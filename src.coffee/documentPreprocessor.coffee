window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.DocumentPreprocessor

  constructor : (@message, @sender, @sendResponse, @storageManager) ->
    @document = {}
    @currentNumberOfFetchedFeatures = 0
    @numberOfFetchedFeatures = 5
    console.log "new Document processor created to handle the mem0r1e from #{sender.tab.url}"
    @preprocessMem0r1e()
  
  preprocessMem0r1e : () ->
    @set "timeStamp", new Date().getTime()
    @getLanguage @sender.tab
    @takeScreenshot @sender.windowId, @sender.tab
    @set "URL", @sender.tab.url
    @set "DOM", @message.content
    return
  
  getLanguage : (tab) =>
    chrome.tabs.detectLanguage tab.id, (language) =>
      @set "language", language
      return
    return
  
  set : (property, value) -> 
    @document[property] = value
    @currentNumberOfFetchedFeatures++
    if @IsReadyToStore()
      @storetemporaryDocument()
    return
  
  storetemporaryDocument : () ->
    @storageManager.store "temporary", @document, @sendResponse
  
  IsReadyToStore : () ->
    return @currentNumberOfFetchedFeatures is @numberOfFetchedFeatures
    
  IsDone : () ->
    return false
    
  takeScreenshot : (windowID, tab) =>
    chrome.tabs.captureVisibleTab windowID, {quality : 10, format : "jpeg"}, (dataUrl) =>
      @set "screenshot", dataUrl
      return
    return