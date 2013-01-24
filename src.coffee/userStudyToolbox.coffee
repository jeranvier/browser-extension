window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.UserStudyToolbox

  constructor : (@storageManager)->
    @sessionPageDisplayed = 0
    @currentCount = 0
    @initLastDump()
    @dumpServerURL = "http://127.0.0.1:8080/"
    @checkIfNeedNewContext()
    @dumpDailyData()
    console.log "Toolbox for the user study is ready"
  
  initLastDump : () ->
    lastDump = localStorage.getItem 'lastDump'    
    if not lastDump?
      localStorage.setItem 'lastDump', 0
  
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
        when "addLabel" then @addLabel message.content, sendResponse
        when "deleteLabel" then @deleteLabel message.content, sendResponse
        when "retrieveLabels" then @retrieveLabels sendResponse
        when "saveSession" then @saveSession message.content, sendResponse
        when "newActivity" then @checkIfNeedNewContext sendResponse
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
    @sessionPageDisplayed = false
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
    if (new Date().getTime() - @getLastActivityTime())>10*1000*60 and not @sessionPageDisplayed
      chrome.tabs.create {'url': chrome.extension.getURL('html/sessionInfo.html'), pinned:true}
      @sessionPageDisplayed = true
    @updateLastActivityTime()
  
  countDumpedData : (sendResponse) ->
    sendResponse @currentCount
    
  countDumpData : (sendResponse) ->
    query = new mem0r1es.Query().from("temporary")
    @storageManager.count query, (results) =>
      sendResponse results

  dumpDailyData : () =>
    lastDump = parseInt(localStorage.getItem('lastDump'), 10)
    @now = new Date().getTime()
    if @now < lastDump + 1000*60*60*24
      console.log "no dump needed"
      return
    else
      console.log "dumping the latest data"
    query = new mem0r1es.Query().from("temporary").where("timestamp", "between", lastDump, true , @now, false).getChildren [{name:"userAction", objectStore:"userActions"},{name:"screenshot", objectStore:"screenshots"}]
    @storageManager.get query, (results) =>
      console.log "dumping #{results.length} pages"
      if results.length > 50
        console.log "number of pages too important to be dumped remotely"
        return
      if results.length > 0
        page = results.shift()
      else
        page = null
      @tidyDumpUp page, results, {}, @sendToServer
    return
  
  tidyDumpUp : (page, results, dump, callback) =>

    if page is null
      callback dump
      return
      
    if dump[page._userStudySessionId]?
      dump[page._userStudySessionId].pages.push page
      if results.length > 0
        page = results.shift()
        @currentCount++
      else
        page = null
      
      @tidyDumpUp page, results, dump, callback
    else
      query = new mem0r1es.Query().from("userStudySessions").where("userStudySessionId", "equals", parseInt(page._userStudySessionId, 10))
      @storageManager.get query, (subResults) =>
        dump[page._userStudySessionId] = {}
        dump[page._userStudySessionId].userStudySession = subResults[0]
        dump[page._userStudySessionId].pages = []
        dump[page._userStudySessionId].pages.push page
        if results.length > 0
          page = results.shift()
          @currentCount++
        else
          page = null
        
        @tidyDumpUp page, results, dump, callback
  
  sendToServer : (dump) =>
    formData = new FormData()
    formData.append "dump", JSON.stringify(dump)
    
    xmlhttp = new XMLHttpRequest()
    xmlhttp.open "POST", @dumpServerURL, true
    xmlhttp.send(formData)
    xmlhttp.onreadystatechange = () =>
      if (xmlhttp.readyState isnt 4)
        return
      if (xmlhttp.status is 200) 
        console.log "dump done."
        localStorage.setItem 'lastDump', @now

  dumpData : (sendResponse) =>
    console.log "dumping data for user study"
    @currentCount=0
    query = new mem0r1es.Query().from("temporary").getChildren [{name:"userAction", objectStore:"userActions"},{name:"screenshot", objectStore:"screenshots"}]
    @storageManager.get query, (results) =>
      console.log "dumping #{results.length} pages"
      page = results.shift()
      @currentCount++
      @tidyDumpUp page, results, {}, sendResponse
    return
                    
  storeMem0r1esFile : (messageContent, sendResponse) ->
    @storageManager.clearStore "temporary"
    @storageManager.clearStore "userStudySessions"
    @storageManager.clearStore "userActions"
    @storageManager.clearStore "screenshots"
    try
      mem0ries = JSON.parse messageContent     
    catch error 
      sendResponse "Invalid json"

    count=0
    
    for key, session of mem0ries
      for page in session.pages
        count++
    for key, session of mem0ries
      @storageManager.store "userStudySessions", session.userStudySession
      for page in session.pages
        @storageManager.store "temporary", page, () =>
          count--
          if count is 0
            sendResponse "Mem0r1es Loaded"
  
  countMem0r1es : (sendResponse) =>
    query = new mem0r1es.Query().from("temporary")
    @storageManager.count query, (results) =>
      sendResponse results
  
  getMem0r1es : (messageContent, sendResponse) ->
    query = new mem0r1es.Query().from("temporary").where("timestamp","greaterThan",0).getChildren([{name:"screenshot", objectStore:"screenshots"}, {name:"userActions", objectStore:"userActions"}]).limit messageContent.limitMin, messageContent.limitMax
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