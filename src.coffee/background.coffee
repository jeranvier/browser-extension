window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.Background
  init : () ->
    console.log "initializing mem0r1es"
    #open and initialize the database
    @storageManager = new mem0r1es.StorageManager()
    @storageManager.openDB()
    
    #Create the icon for the popup
    @icon = new mem0r1es.Icon()
    
    #Initialize the navigation listener
    @navigationListener = new mem0r1es.NavigationListener()
    
    #Initialize the DSL processor
    @dslProcessor = new mem0r1es.DSLProcessor @storageManager
    
    #Initialize the document preprocessor pool
    @DocumentPreprocessorPool = new mem0r1es.DocumentPreprocessorPool @storageManager
      
    #Initialize the navigation listener
    @userStudyToolbox = new mem0r1es.UserStudyToolbox @storageManager
    
    #Initialize the message listener
    @setupMessageListener()
    
    @state = "on"
  
  activate : (sendResponse = null) ->
    console.log "reactivating mem0r1es"
    @icon = new mem0r1es.Icon()
    @navigationListener = new mem0r1es.NavigationListener()
    @state = "on"
    if sendResponse?
      sendResponse {status : "ok", text: "Go incognito"}
    
  deactivate : (sendResponse = null) ->
    console.log "deactivating mem0r1es"
    #modify the icon for the popup
    @icon = new mem0r1es.Icon "incognito"
    
    #kill the navigation listener
    @navigationListener.shutdown()
    delete @navigationListener
   
    @state = "off"
    if sendResponse?
      sendResponse {status : "ok", text: "activate mem0r1es"}
      
  toggleMem0r1es : (sendResponse) ->
    if @state is "on"
      @deactivate sendResponse
    else if @state is "off"
      @activate sendResponse
  
  getState : (sendResponse) ->
    if @state is "on"
      text = "Go incognito"
    else if @state is "off"
      text = "activate mem0r1es"
    sendResponse {state : @state, text: text}
  
  #send a message to a specific tab
  sendMessage : (tabId, message, callback) ->
    chrome.tabs.sendMessage tabId, message, (response) ->
      callback(response)
      return
    return
  
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
      when "toggleMem0r1es" then @toggleMem0r1es sendResponse
      when "getState" then @getState sendResponse
      else console.log "Could not understand the command #{message.title}"
    return
  
  #setup the listener to messages from the popup (GUI) and redirect these messages to the right module
  #along with the method to send the response
  setupMessageListener : () ->
    chrome.extension.onMessage.addListener((request, sender, sendResponse) =>
      console.log "redirecting a message to #{request.module}"
      switch(request.module)
        when "storageManager"
          @storageManager.onMessage request.message, sender, sendResponse
        when "navigationListener"
          @navigationListener.onMessage request.message, sender, sendResponse
        when "documentPreprocessor"
          if @state is "on"
            @DocumentPreprocessorPool.onMessage request.message, sender, sendResponse 
        when "DSLProcessor"
          @dslProcessor.onMessage request.message, sender, sendResponse
        when "background"
          @onMessage request.message, sender, sendResponse
        when "userStudyToolbox"
          @userStudyToolbox.onMessage request.message, sender, sendResponse
        else console.log "Could not redirect the message from the popup user interface. #{request.module} is not a valid module"
      #the listener must return true if the response needs to be sent asynchronously
      return true)
    console.log "Message listener ready"
    return

background = new mem0r1es.Background
background.init()