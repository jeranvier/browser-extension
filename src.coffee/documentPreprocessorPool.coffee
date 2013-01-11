window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.DocumentPreprocessorPool
  
  constructor : (@storageManager) ->
    @listCleanerInterval = 1000*60*5
    @referersList = {}
    @startReferersListCleaner()
    @documentPreprocessors = {}
    chrome.tabs.onActivated.addListener (activeInfo) =>
      if @activeTab
        try
          @documentPreprocessors[@activeTab.id].setTabActivated false
        catch error
        @activeTab = {id:activeInfo.tabId, windowId : activeInfo.windowId}
        try
          @documentPreprocessors[@activeTab.id].setTabActivated true
        catch error
      else
        @activeTab = {id:activeInfo.tabId, windowId : activeInfo.windowId}
    chrome.tabs.onRemoved.addListener (tabId, removeInfo) =>
      console.log "deleting the documentPreprocessor for tabId : #{tabId}"
      delete @documentPreprocessors[tabId]
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
    
  createDocumentPreprocessor : (message, sender, sendResponse) =>
    tabId =sender.tab.id
    URL = sender.tab.url
    if not @documentPreprocessors[tabId]? or @documentPreprocessors[tabId].document.URL.valueOf() isnt URL.valueOf()
      if @referersList[URL]?
        referer = @referersList[URL].referer
        delete @referersList[URL]
      else
        referer = "unknown"
      @documentPreprocessors[tabId] = new mem0r1es.DocumentPreprocessor message, referer, sender, sendResponse, @storageManager, @activeTab
    else
      @documentPreprocessors[tabId].updateContent message
      sendResponse {title:"documentPreprocessorCreated", pageId:@documentPreprocessors[tabId].pageId}
    return
    
  updateMem0r1e : (message, sender, sendResponse) =>
    tabId =sender.tab.id
    URL = sender.tab.url
    @documentPreprocessors[tabId].update message, sendResponse
    return
  
  addRefererEntry : (target, referer) ->
    @referersList[target] ={referer:referer, timestamp: new Date().getTime()}

  startReferersListCleaner : () =>
    window.setInterval () =>
      now = new Date().getTime()
      for url, referer of @referersList
        if referer.timestamp > now - @listCleanerInterval
          delete @referersList[url]
      console.log "referers list cleaned"
    , @listCleanerInterval 