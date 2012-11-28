window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.Popup

  constructor : () ->
    document.addEventListener 'DOMContentLoaded', @createListeners
    @sendMessage("background", {title:"getState", content:""}, (response) ->
      document.getElementById("toggleMem0r1es").innerText = response.text
      return)
    return
    
  #create the event listeners for the buttons
  createListeners : () =>
    document.getElementById("clearDB").addEventListener "click", ()=>
      @sendMessage("storageManager", {title:"clearDB", content:""}, @clearDBCallback)
      return
    , false
    
    document.getElementById("toggleMem0r1es").addEventListener "click", ()=>
      @sendMessage("background", {title:"toggleMem0r1es", content:""}, @toggleMem0r1esCallback)
      return
    , false
    
    document.getElementById("DSRulesButton").addEventListener "click", ()=>
      chrome.tabs.create 'url': chrome.extension.getURL('html/options.html')
    , false
    
    document.getElementById("cameraButton").addEventListener "click", ()=>
      chrome.tabs.create {'url': chrome.extension.getURL('html/sessionInfo.html'), pinned:true}
    , false
    return
  
      
  #Send message from the popup (UI) to the extension.
  #Arguments: The module to which redirect the message, the message itself as a json and a callback to handle the response
  sendMessage : (module,message, callback) ->
    chrome.extension.sendMessage({module:module, message:message}, (response)->
      if callback?
        callback response
      return
      )
    return
    
  #Callback triggered by the response from background.html related to a clearDB message
  clearDBCallback :(response)=>
    @displayMessage response.message
    return
    
  #Callback triggered by the response from background.html related to the (de)activation of the extension
  toggleMem0r1esCallback :(response)=>
    document.getElementById("toggleMem0r1es").innerText = response.text
    if response.status isnt "ok"
      @displayMessage response.message
    return
    
  #Displays a message in the notification area of the popup.
  #The message is a json with a content and a level (success, notice, warning, error)
  displayMessage : (message ) ->
    node = document.createElement "div"
    node.setAttribute("class", "notification")
    node.setAttribute("id", message.level)
    textnode=document.createTextNode message.content
    node.appendChild textnode
    document.getElementById("notifications").appendChild node
    setTimeout () ->
      node.setAttribute("class", "notification hide")
      setTimeout () ->
        document.getElementById("notifications").removeChild node
        return
      ,500
      return
    ,3000
    return

popup = new mem0r1es.Popup