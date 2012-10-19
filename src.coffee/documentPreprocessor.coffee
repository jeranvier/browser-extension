window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.DocumentPreprocessor

  constructor : (@message, @sender, @sendResponse, @storageManager) ->
    @pageId = @message.content.pageId
    @document = {}
    @currentNumberOfFetchedFeatures = 0
    @numberOfFetchedFeatures = 6
    console.log "new Document processor created to handle the mem0r1e from #{sender.tab.url}"
    @preprocessMem0r1e()
  
  preprocessMem0r1e : () ->
    @getLanguage @sender.tab
    @takeScreenshot @sender.windowId, @sender.tab
    @set "URL", @sender.tab.url
    @set "timestamp", @message.content.timestamp
    @set "pageId", @message.content.pageId
    @set "DOM", @message.content.DOMtoJSON
    return
  
  getLanguage : (tab) =>
    chrome.tabs.detectLanguage tab.id, (language) =>
      @set "language", language
      return
    return
  
  set : (property, value) -> 
    @document[property] = value
    @currentNumberOfFetchedFeatures++
    if @isReadyToStore()
      @storetemporaryDocument()
    return
  
  storetemporaryDocument : (sendResponse = @sendResponse) ->
    @storageManager.store "temporary", @document, sendResponse
    return
  
  isReadyToStore : () ->
    return @currentNumberOfFetchedFeatures is @numberOfFetchedFeatures
    
  takeScreenshot : (windowID, tab) =>
    chrome.tabs.captureVisibleTab windowID, {quality : 10, format : "jpeg"}, (dataUrl) =>
      @set "screenshot", dataUrl
      return
    return
    
  update : (message, sendResponse) -> #TODO Handle the sendResponse
    if message.content.event.type is "unload"
      @sendResponse = sendResponse
    if not @document.userEvents
      @document.userEvents = new Array()
    @document.userEvents.push message.content.event
    if @isReadyToStore()
      @storetemporaryDocument(sendResponse)