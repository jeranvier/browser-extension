window.mem0r1es = {} if not window.mem0r1es?
mem0r1es.injectable = {}

mem0r1es.injectable.DOMtoJSON = (node)->
  JSONNode = {}
  JSONNode.tag = node.nodeName.toLowerCase();
  JSONNode.attributes = {}
  DOMAttributes = node.attributes
  for i in [0 .. DOMAttributes.length-1] by 1
    JSONNode.attributes[DOMAttributes[i].name] = DOMAttributes[i].value
  JSONNode.style = node.getAttribute "style"
  if JSONNode.attributes.length is 0
    delete JSONNode.attributes
  
  JSONNode.children = new Array()
  DOMChildren = node.childNodes;
  for i in [0 .. DOMChildren.length-1] by 1
    
    if node.childNodes[i].nodeType is 1
      JSONNode.children.push mem0r1es.injectable.DOMtoJSON DOMChildren[i]
    if DOMChildren[i].nodeType is 3 and JSONNode.tag isnt "script" and DOMChildren[i].nodeValue.replace(/[\n\t]*/g, "").length isnt 0
      JSONNode.text = DOMChildren[i].nodeValue.replace /[\n\t]*/g,""
  JSONNode

mem0r1es.injectable.sendMessage = (module, message, callback)->
  if chrome.extension? 
    chrome.extension.sendMessage {module:module, message:message},(response)->
      if callback?
        callback response
      return
  return
  
mem0r1es.injectable.getPageId = () ->
  if not window.mem0r1es.pageId?
    window.mem0r1es.pageId = "#{document.location.href.split("/")[2]}_#{new Date().getTime()}_#{Math.floor(Math.random()*1000)}"
  return mem0r1es.pageId

mem0r1es.injectable.getInitialTimeStamp = () ->
  if not window.mem0r1es.initialTimeStamp?
    window.mem0r1es.initialTimeStamp = new Date().getTime()
  return mem0r1es.initialTimeStamp
  
mem0r1es.injectable.clickListener = (event) ->
  mem0r1es.injectable.sendMessage "documentPreprocessor", {
    title : "mem0r1eEvent"
    content :
      pageId : mem0r1es.injectable.getPageId()
      event :
        timestamp: new Date().getTime()
        type : "click"
        target : mem0r1es.injectable.DOMtoJSON event.target
    }, null
  return

mem0r1es.injectable.mouseupListener = (event) ->
  currentSelection = window.getSelection()
  
  if typeof(currentSelection) is "undefined" or not lastSelection?
    lastSelection = currentSelection
  
  if currentSelection is lastSelection and typeof(currentSelection) isnt "undefined" and currentSelection.toString().length isnt 0
    currentSelection = currentSelection.toString()
    mem0r1es.injectable.sendMessage "documentPreprocessor", {
    title : "mem0r1eEvent"
    content :
      pageId : mem0r1es.injectable.getPageId()
      event :
        timestamp: new Date().getTime()
        type : "highlight"
        data : currentSelection
    }, null
  
  lastSelection = currentSelection
  return

mem0r1es.injectable.unloadListener = (event) ->
  mem0r1es.injectable.sendMessage "documentPreprocessor", {
    title : "mem0r1eEvent"
    content :
      pageId : mem0r1es.injectable.getPageId()
      event :
        timestamp: new Date().getTime()
        type : "unload"
    }, null
  return

mem0r1es.injectable.createNewMem0r1e = () ->  
  console.log mem0r1es.injectable.getPageId()
  mem0r1es.injectable.sendMessage "documentPreprocessor", {
    title : "newMem0r1e"
    content :
      pageId : mem0r1es.injectable.getPageId()
      timestamp: mem0r1es.injectable.getInitialTimeStamp()
      DOMtoJSON : mem0r1es.injectable.DOMtoJSON document.getElementsByTagName("html")[0]
    }, (response) =>
      window.mem0r1es.pageId = response.pageId
      console.log mem0r1es.injectable.getPageId()
      
 
mem0r1es.injectable.loadDSRules = () ->
  mem0r1es.injectable.sendMessage "DSLProcessor", {title : "getRulesForURL"}, mem0r1es.injectable.DSRulesHandler
  return

mem0r1es.injectable.DSRulesHandler = (DSRules) ->
  for rule in DSRules
    data = eval(rule.exec)()
    if data isnt null
      mem0r1es.injectable.sendMessage "documentPreprocessor", {
        title : "mem0r1eDSFeature"
        content :
          pageId : mem0r1es.injectable.getPageId()
          feature :
            timestamp: new Date().getTime()
            type : rule.name
            data : data
        }, null
  return

mem0r1es.createListeners = () ->
  document.getElementsByTagName("html")[0].addEventListener "click", mem0r1es.injectable.clickListener, false
  document.getElementsByTagName("html")[0].addEventListener "click", mem0r1es.injectable.clickListener, false
  document.getElementsByTagName("html")[0].addEventListener "mouseup", mem0r1es.injectable.mouseupListener, false
  window.addEventListener "beforeunload", mem0r1es.injectable.unloadListener, false
  
mem0r1es.injectable.initialize = () ->
  if not window.mem0r1es.pageId?
    mem0r1es.injectable.getPageId()
    mem0r1es.injectable.createNewMem0r1e()
    mem0r1es.injectable.loadDSRules()
    mem0r1es.createListeners()
  
mem0r1es.eventCatched = (title, data, callback) ->
  mem0r1es.injectable.sendMessage "documentPreprocessor", {
    title : "mem0r1eDSEvent"
   content :
     pageId : mem0r1es.injectable.getPageId()
     timestamp : mem0r1es.injectable.getInitialTimeStamp()
     event :
       title : title
       data : data
   }, null
   

mem0r1es.injectable.initialize()