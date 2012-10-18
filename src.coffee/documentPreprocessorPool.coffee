window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.DocumentPreprocessorPool
  
  constructor : (@storageManager) ->
    @documentPreprocessors = new Array()
    console.log "document preprocessor pool ready"
    
  #Handles messages received from background.js
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
      when "newMem0r1e" then @createDocumentPreprocessor message, sender, sendResponse
      else console.log "Could not understand the command #{message.title}"
    return
    
  createDocumentPreprocessor  : (message, sender, sendResponse) ->
    @documentPreprocessors.push(new mem0r1es.DocumentPreprocessor message, sender, sendResponse, @storageManager)
    return