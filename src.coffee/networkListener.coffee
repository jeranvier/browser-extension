window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.NetworkListener

  constructor : ()->
    chrome.webNavigation.onCompleted.addListener this.onCompleted,{urls: ["*://*/*"]}, []
    
  onBeforeRequestCallback : (details) ->
    console.log details.url
    return