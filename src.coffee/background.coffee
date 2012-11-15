window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.Background
  init : () ->
    #open and initialize the database
    @storageManager = new mem0r1es.StorageManager()
    @storageManager.openDB()
    
    #Create the icon for the popup
    @icon = new mem0r1es.Icon();
    
    #Initialize the navigation listener
    @navigationListener = new mem0r1es.NavigationListener()
    
    #Initialize the DSL processor
    @dslProcessor = new mem0r1es.DSLProcessor @storageManager
    
    #Initialize the document preprocessor pool
    @DocumentPreprocessorPool = new mem0r1es.DocumentPreprocessorPool @storageManager
    
    @setupMessageListener()
  
  #send a message to a specific tab
  sendMessage : (tabId, message, callback) ->
    chrome.tabs.sendMessage tabId, message, (response) ->
      callback(response)
      return
    return
  
  #setup the listener to messages from the popup (GUI) and redirect these messages to the right module
  #along with the method to send the response
  setupMessageListener : () ->
    chrome.extension.onMessage.addListener((request, sender, sendResponse) =>
      console.log "redirecting a message to #{request.module}"
      switch(request.module)
        when "storageManager" then @storageManager.onMessage request.message, sender, sendResponse
        when "navigationListener" then @navigationListener.onMessage request.message, sender, sendResponse
        when "documentPreprocessor" then @DocumentPreprocessorPool.onMessage request.message, sender, sendResponse
        when "DSLProcessor" then @dslProcessor.onMessage request.message, sender, sendResponse
        else console.log "Could not redirect the message from the popup user interface. #{request.module} is not a valid module"
      #the listener must return true if the response needs to be sent asynchronously
      return true)
    return

background = new mem0r1es.Background
background.init()