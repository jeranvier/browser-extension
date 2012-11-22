window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.UserStudyToolbox

  constructor : (@storageManager)->
    console.log "Toolbox for the user study is ready"
  
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
        when "addLabel" then @addLabel message.content, sendResponse
        when "deleteLabel" then @deleteLabel message.content, sendResponse
        when "retrieveLabels" then @retrieveLabels sendResponse
        when "saveSession" then @saveSession message.content, sendResponse
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
      sendResponse()
    return