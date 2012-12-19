window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.UserStudyToolbox

  constructor : (@storageManager)->
    @currentCount = 0
    @checkIfNeedNewContext()
    console.log "Toolbox for the user study is ready"
  
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
        when "addLabel" then @addLabel message.content, sendResponse
        when "deleteLabel" then @deleteLabel message.content, sendResponse
        when "retrieveLabels" then @retrieveLabels sendResponse
        when "saveSession" then @saveSession message.content, sendResponse
        when "newActivity" then @checkIfNeedNewContext sendResponse
        when "getUserStudyWebsites" then @getUserStudyWebsites sendResponse
        when "storeUserStudyWebsite" then @storeUserStudyWebsite message.content, sendResponse
        when "deleteUserStudyWebsite" then @deleteUserStudyWebsite message.content, sendResponse 
        when "countDumpData" then @countDumpData sendResponse 
        when "countDumpedData" then @countDumpedData sendResponse 
        when "dumpData" then @dumpData sendResponse  
        when "storeMem0r1esFile" then @storeMem0r1esFile message.content, sendResponse
        when "getMem0r1es" then @getMem0r1es message.content, sendResponse
        when "countMem0r1es" then @countMem0r1es sendResponse
    return
    
  addLabel : (messageContent, sendResponse) =>
    @storageManager.store "labels", messageContent.label, () =>
      @retrieveLabels sendResponse
    return
    
  deleteLabel : (messageContent, sendResponse) =>
    @storageManager.delete "labels", messageContent.labelId, () =>
      @retrieveLabels sendResponse
    return
    
  retrieveLabels : (sendResponse) ->
    query = new mem0r1es.Query().from("labels")
    @storageManager.get query, sendResponse
    return
    
  saveSession : (messageContent, sendResponse) =>
    @storageManager.store "userStudySessions", messageContent, () =>
      @updateLastActivityTime()
      localStorage.setItem 'lastUserStudySessionId', messageContent.userStudySessionId
      sendResponse()
    return
    
  updateLastActivityTime : () ->
    lastActivityTime = new Date().getTime()
    localStorage.setItem 'lastActivityTime', lastActivityTime
    return lastActivityTime
    
  getLastActivityTime : () ->
    lastActivityTime = localStorage.getItem 'lastActivityTime'
    if lastActivityTime is null
      localStorage.setItem 'lastActivityTime', 0
      return 0
    return lastActivityTime
    
  checkIfNeedNewContext : () ->
    if (new Date().getTime() - @getLastActivityTime())>10*1000*60
      chrome.tabs.create {'url': chrome.extension.getURL('html/sessionInfo.html'), pinned:true}
    @updateLastActivityTime()
    
  getUserStudyWebsites : (sendResponse) ->
    query = new mem0r1es.Query().from("parameters").where("parameterId", "equals", "userStudyWebsites")
    @storageManager.get query, (results) ->
      if results.length is 1
        sendResponse results[0].value
        return
      else
        sendResponse {}
        return
      return
    return

  deleteUserStudyWebsite : (websiteId, sendResponse) =>
    @getUserStudyWebsites (websites) =>
      delete websites[websiteId]
      @storageManager.store "parameters", {parameterId:"userStudyWebsites", value:websites}, sendResponse
    
  storeUserStudyWebsite : (website, sendResponse) =>
    @getUserStudyWebsites (websites) =>
      websites[website.websiteId] = website
      @storageManager.store "parameters", {parameterId:"userStudyWebsites", value:websites}, sendResponse
  
  countDumpedData : (sendResponse) ->
    sendResponse @currentCount
    
  countDumpData : (sendResponse) ->
    @currentCount = 0
    @getUserStudyWebsites (websites) =>
      count = Object.keys(websites).length
      if count is 0
        sendResponse 1
        return
      total = 0
      for websiteId, website of websites
        @currentCount++
        do (website) =>
          query = new mem0r1es.Query().from("temporary").where("URL", "between", "#{website.pattern}", false , "#{website.pattern.slice 0,-1}#{String.fromCharCode(website.pattern.charCodeAt(website.pattern.length-1)+1) }", true)
          @storageManager.count query, (results) =>
            total += results
            if count is 1
              sendResponse total
            else
              count--
          
  dumpData : (sendResponse) ->
    console.log "dumping data for user study"
    dump = {}
    lastDump = localStorage.getItem 'lastActivityTime'
    if lastDump is null
      lastDump = 0
    
    @getUserStudyWebsites (websites) =>
      count = Object.keys(websites).length
      if count is 0
        @currentCount = 1
        sendResponse dump
        return
      for websiteId, website of websites
        do (website) =>
          query = new mem0r1es.Query().from("temporary").where("URL", "between", "#{website.pattern}", false , "#{website.pattern.slice 0,-1}#{String.fromCharCode(website.pattern.charCodeAt(website.pattern.length-1)+1) }", true).getChildren [{name:"userAction", objectStore:"userActions"},{name:"screenshot", objectStore:"screenshots"}]
          
          @storageManager.get query, (results) =>
            subcount = results.length
            for result in results
              do(result) =>
                query = new mem0r1es.Query().from("userStudySessions").where("userStudySessionId", "equals", parseInt(result._userStudySessionId, 10))
                @storageManager.get query, (subResults) =>
                  result.userStudySession = subResults[0]
                  if subcount is 1
                    dump[website.title] = results
                    if count is 1
                      sendResponse dump
                    else
                      count--
                  else
                    subcount--
                    @currentCount++
                    
  storeMem0r1esFile : (messageContent, sendResponse) ->
    @storageManager.clearStore "temporary"
    @storageManager.clearStore "userStudySessions"
    @storageManager.clearStore "userActions"
    @storageManager.clearStore "screenshots"
    try
      mem0ries = JSON.parse messageContent     
    catch error
      response = "Invalid json"
      sendResponse response
    
    count = 0
    for key, websites of mem0ries
      count = count + websites.length
    for key, websites of mem0ries
      for website in websites
        @storageManager.store "userStudySessions", website.userStudySession
        delete website.userStudySession
        @storageManager.store "temporary", website, () =>
          if count is 1
            sendResponse "Mem0r1es Loaded"
          else
            count--
  
  countMem0r1es : (sendResponse) =>
    query = new mem0r1es.Query().from("temporary")
    @storageManager.count query, (results) =>
      sendResponse results
  
  getMem0r1es : (messageContent, sendResponse) ->
    query = new mem0r1es.Query().from("temporary").where("timestamp","greaterThan",0).getChildren([{name:"screenshot", objectStore:"screenshots"}]).limit messageContent.limitMin, messageContent.limitMax
    @storageManager.get query, (results) =>
      count = results.length
      for result in results
        do(result) =>
          query = new mem0r1es.Query().from("userStudySessions").where("userStudySessionId", "equals", parseInt(result._userStudySessionId, 10))
          @storageManager.get query, (subResults) =>
            result.userStudySession = subResults[0]
            if count is 1
              sendResponse results
            else
              count--