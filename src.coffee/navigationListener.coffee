window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.NavigationListener

  constructor : ()->
    chrome.webNavigation.onCompleted.addListener this.onCompleted,{urls: ["*://*/*"]}, []
    console.log "navigation listener ready"
    
  shutdown : () ->
    chrome.webNavigation.onCompleted.removeListener(this.onCompleted);
    console.log "navigation listener down"
    
  onCompleted : (details)->
    if not details.url.match "about:blank"
      chrome.tabs.executeScript details.tabId, {file: "js/injectable.js"}