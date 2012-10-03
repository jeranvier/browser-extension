window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.NavigationListener

  constructor : ()->
    chrome.webNavigation.onCompleted.addListener this.onCompleted,{urls: ["*://*/*"]}, []
  
  getDOMCallback : (response)->
    console.log response
    
  onMessage : (response)->
    switch (response.title)
      when "DOMtoJSON" then @getDOMCallback response.content
    
  onCompleted : (details)->
    console.log "(#{details.tabId}) #{details.url}"
    if not details.url.match "about:blank"
      chrome.tabs.executeScript details.tabId, {file: "js/injectable.js"}