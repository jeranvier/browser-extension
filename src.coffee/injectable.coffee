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

mem0r1es.injectable.clickListener = (event) ->
  return

mem0r1es.injectable.sendMessage "documentPreprocessor", {title : "newMem0r1e" , content : mem0r1es.injectable.DOMtoJSON document.getElementsByTagName("html")[0]}
#document.getElementsByTagName("html")[0].addEventListener "click", mem0r1es.injectable.clickListener, false