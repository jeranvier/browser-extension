window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.DocumentPreprocessorPool
  
  constructor : (@storageManager) ->
    @documentPreprocessors = new Array()
    console.log "document preprocessor pool ready"
    
  #Handles messages received from background.js
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
      when "newMem0r1e" then @createDocumentPreprocessor message, sender, sendResponse
      when "mem0r1eEvent" then @updateMem0r1e message, sender, sendResponse
      when "mem0r1eDSFeature" then @updateMem0r1e message, sender, sendResponse
      when "mem0r1eDSEvent" then @updateMem0r1e message, sender, sendResponse
      else console.log "Could not understand the command #{message.title}"
    return
    
  createDocumentPreprocessor : (message, sender, sendResponse) ->
    @documentPreprocessors.push(new mem0r1es.DocumentPreprocessor message, sender, sendResponse, @storageManager)
    return
    
  updateMem0r1e : (message, sender, sendResponse) =>
    #TODO handle the case when the unload event is not triggered
    if message.content.event? and message.content.event.type is "unload" #if the event is unload then we have to delete the documentPreprocessor once it performed its business
      sendResponse = () =>
        @deleteDocumentPreprocessor message.content.pageId
    for documentPreprocessor in @documentPreprocessors
      if documentPreprocessor.pageId is message.content.pageId
        documentPreprocessor.update message, sendResponse
        return
    return
  
  deleteDocumentPreprocessor : (pageId) ->
    console.log "deleting the documentPreprocessor for pageId : #{pageId}"
    @documentPreprocessors = @documentPreprocessors.filter (documentPreprocessor) -> documentPreprocessor.pageId isnt pageId
    return