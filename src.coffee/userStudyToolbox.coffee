window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.UserStudyToolbox

  constructor : (@storageManager)->
    console.log "Toolbox for the user study is ready"
    @checkIfNeedNewContext()
  
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
        when "addLabel" then @addLabel message.content, sendResponse
        when "deleteLabel" then @deleteLabel message.content, sendResponse
        when "retrieveLabels" then @retrieveLabels sendResponse
        when "saveSession" then @saveSession message.content, sendResponse
        when "newActivity" then @checkIfNeedNewContext sendResponse
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
      sendResponse()
    return
    
  updateLastActivityTime : () ->
    lastActivityTime = new Date().getTime()
    localStorage.setItem 'lastActivityTime', lastActivityTime
    return lastActivityTime
    
  getLastActivityTime : () ->
    lastActivityTime = localStorage.getItem 'lastActivityTime'
    if lastActivityTime is null
      return @updateLastActivityTime()
    return lastActivityTime
    
  checkIfNeedNewContext : () ->
    if (new Date().getTime() - @getLastActivityTime())>10*1000*60
      chrome.tabs.create 'url': chrome.extension.getURL('html/sessionInfo.html')
    @updateLastActivityTime()