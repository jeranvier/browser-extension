window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.DocumentPreprocessor

  constructor : (@message, @sender, @sendResponse, @storageManager) ->
    @pageId = @message.content.pageId
    @document = {}
    @currentNumberOfFetchedFeatures = 0
    @numberOfFetchedFeatures = 6
    console.log "new Document processor created to handle the mem0r1e from #{sender.tab.url} (#{@pageId})"
    @preprocessMem0r1e()
  
  preprocessMem0r1e : () ->
    @getLanguage @sender.tab
    @takeScreenshot @sender.windowId, @sender.tab
    @set "URL", @sender.tab.url
    @set "reverseDomainName", @sender.tab.url.split("/")[2].split(".").reverse().join(".")
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
      @storageManager.store "screenshots", {screenshotId:@pageId, _pageId:@pageId, screenshot:dataUrl}
      return
    return
    
  update : (message, sendResponse) -> #TODO Handle the sendResponse
    switch message.title
      when "mem0r1eEvent" then @createEvent(message, sendResponse)
      when "mem0r1eDSFeature" then @createDSFeature(message, sendResponse)
  
  createDSFeature : (message, sendResponse) ->
    if not @document.DSFeatures
      @document.DSFeatures = new Array()
    @document.DSFeatures.push message.content.feature
    if @isReadyToStore()
      @storetemporaryDocument(sendResponse)
  
  createEvent : (message, sendResponse) ->
    if message.content.event.type is "unload"
      @sendResponse = sendResponse
    userAction = message.content.event
    userAction._pageId = @pageId
    userAction.userActionId = "#{userAction.type}_#{new Date().getTime()}_#{Math.floor(Math.random()*100)}"
    @storageManager.store "userActions", userAction, sendResponse