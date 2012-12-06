window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.sessionInfo

  constructor : () ->
    document.addEventListener 'DOMContentLoaded', @createListeners
    document.addEventListener 'DOMContentLoaded', @initializeCamera
    document.addEventListener 'DOMContentLoaded', @getCoordinate
    
  #Send message from the popup (UI) to the extension.
  #Arguments: The module to which redirect the message, the message itself as a json and a callback to handle the response
  sendMessage : (module, message, callback) ->
    chrome.extension.sendMessage({module:module, message:message}, (response)->
      if callback?
        callback response
      return
      )
    return
    
  initializeCamera : () =>
    camera=document.getElementById "camera"
    navigator.webkitGetUserMedia {video:true},(stream) =>
      camera.src=window.webkitURL.createObjectURL(stream)
      @localMediaStream=stream
    ,() ->
      console.log "couldn't start camera"
      
  retrieveLabels : (callback) ->
    @sendMessage "userStudyToolbox", {title:"retrieveLabels"}, (response) =>
      @labels=response
      callback()
    return
  
  createListeners : () =>
    document.getElementById("takePicture").addEventListener "click", () =>
      @takePicture()
    , false
    
    document.getElementById("camera").addEventListener "click", () =>
      @takePicture()
    , false
    
    document.getElementById("validationLink").addEventListener "click", () =>
      @setupValidation()
    , false
    
    
    window.addEventListener "message", (event) =>
      clearInterval(@gmapInitMessage)
      if event.data.title is "latestCoordinates"
        @setStaticMap(event.data.content)
      return
      
    document.getElementById("newLabelButton").addEventListener 'click', () =>
      @addLabel()
      return
      
    document.getElementById("newLabelInput").addEventListener "keydown",(event) =>
      if event.keyCode is 13
        @addLabel()
      return

    document.getElementById("closeSessionInfo").addEventListener 'click', () =>
      document.getElementById("closeSessionInfo").style.display = "none"
      @saveSessionInfoAndClose()
      return
    
    document.getElementById("closeAndIncognito").addEventListener 'click', () =>
      @sendMessage "background", {title:"toggleMem0r1es"}, () ->
        window.close()
      return
      
    $('#labelManager').on 'shown', () =>
      @generateLabelsManager()
    return
  
  addLabel: (labelText) ->
    labelText = document.getElementById("newLabelInput").value
    document.getElementById("newLabelInput").value=""
    if labelText.length isnt 0
      @sendMessage "userStudyToolbox", {title:"addLabel", content:{label:{labelText: labelText}}}, (response) =>
        @labels=response
        @generateLabels()
        @generateLabelsManager()
        return
    return
    
  removeLabel: (labelId) ->
    @sendMessage "userStudyToolbox", {title:"deleteLabel", content:{labelId:labelId}}, (response) =>
      @labels=response
      @generateLabels()
      @generateLabelsManager()
      return
    return
      
  takePicture : () =>
    if @localMediaStream?
      pic=document.getElementById "pic"
      pic.width=camera.videoWidth;
      pic.height=camera.videoHeight;
      ctx=pic.getContext "2d"
      ctx.drawImage camera, 0, 0
      @pic = pic.toDataURL "image/jpeg"
      $("#locationList").removeClass "disabled"
      $("#locationLink").attr "data-toggle", "tab"
      $("#locationIcon").removeClass "disabled"
      
  getCoordinate : () =>
    if not navigator.geolocation?
      console.log "no geolocation possible"
    else
      navigator.geolocation.getCurrentPosition @coordinateSuccess, @coordinateError
    return

  coordinateSuccess : (position) =>
    latitude = position.coords.latitude
    longitude = position.coords.longitude
    @initializeMap(latitude, longitude)
    @generateLabels(latitude, longitude)
    return

  coordinateError : (error) ->
    console.log "error while geolocating"
    return
    
  initializeMap : (latitude, longitude) ->
    iframe = document.getElementById 'gmap'
    message = {title: 'coordinates',content:{latitude: latitude, longitude: longitude}}
    
    @gmapInitMessage = setInterval ()->
      iframe.contentWindow.postMessage message, '*'
    ,50
    
  generateLabels : (latitude, longitude) =>
    labelsList = document.getElementById "labels"
    while labelsList.hasChildNodes()
      labelsList.removeChild labelsList.lastChild
    @retrieveLabels ()=>
      for label in @labels
        labelSpan = document.createElement "span"
        labelSpan.setAttribute "class", "btn btn-small bold"
        labelSpan.setAttribute "id", label.labelId
        labelSpan.appendChild document.createTextNode label.labelText
        labels.appendChild labelSpan
        labelSpan.addEventListener "click", (event) ->
          for selection in document.getElementsByClassName "label"
            selection.classList.remove "selected"
          event.target.classList.add "selected"
          $("#validationList").removeClass "disabled"
          $("#validationLink").attr "data-toggle", "tab"
          $("#validationIcon").removeClass "disabled"
        ,false
      return
    
  generateLabelsManager: () =>
    labelsList = document.getElementById "labelsList"
    while labelsList.hasChildNodes()
      labelsList.removeChild labelsList.lastChild
      
    for label in @labels
      labelgroup = document.createElement "div"
      labelgroup.className = "btn-group"
      
      labelButton = document.createElement "button"
      labelButton.className = "btn btn-primary btn-mini disabled"
      labelButton.appendChild document.createTextNode label.labelText
      
      labelDeletebutton = document.createElement "button"
      labelDeletebutton.className = "btn btn-mini"
      labelDeletebutton.setAttribute "title", "delete this label"
      labelDeletebutton.addEventListener "click", (event) =>
        @removeLabel parseInt(event.target.id, 10)
      ,false
      labelDeletebuttonIcon = document.createElement "i"
      labelDeletebuttonIcon.className = "icon-trash"
      labelDeletebuttonIcon.setAttribute "id", label.labelId
      labelDeletebutton.appendChild labelDeletebuttonIcon
        
      labelgroup.appendChild labelButton
      labelgroup.appendChild labelDeletebutton
      labelsList.appendChild labelgroup
  
  setupValidation : () =>
    finalPicHTML = document.getElementById("finalPic")
    finalPicHTML.src = @pic
    @label = @getSelectedLabel()
    
    if @label?
      document.getElementById("validationText").innerHTML="You are currently at <span class=\"btn btn-small bold selected active disabled \">#{@label.labelText}</span>."
    else
      document.getElementById("validationText").innerHTML="<div class=\"alert alert-block\"><h4>Warning!</h4>You forgot to provide a label for your location. Go back to step <b>Location</b> to select one.</div>"
      
      
    message = {title: 'getExactCoordinates'}
    iframe = document.getElementById "gmap"
    iframe.contentWindow.postMessage message, '*'
    return
    
  setStaticMap : (messageContent) ->
    @location = messageContent
    locationHTML = document.getElementById "LocationPic"
    locationHTML.src = "http://maps.googleapis.com/maps/api/staticmap?center=#{messageContent.latitude},#{messageContent.longitude}&zoom=18&size=450x338&maptype=hybrid&markers=color:red%7Clabel:Z%7C#{messageContent.latitude},#{messageContent.longitude}&sensor=false"
    return
  
  getSelectedLabel : () ->
    for labelHTML in document.getElementById("labels").children
        if labelHTML.classList.contains("selected")
          for label in @labels
            if label.labelId is parseInt(labelHTML.id, 10)
              return label
    return undefined

  saveSessionInfoAndClose : () ->
    @sendMessage "userStudyToolbox", {title:"saveSession", content:{picture:@pic, location: @location, label: @label, userStudySessionId: new Date().getTime()}}, (response) =>
      @localMediaStream.stop()
      window.close()
    
sessionInfo = new mem0r1es.sessionInfo()