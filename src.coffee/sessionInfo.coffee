window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.sessionInfo

  constructor : () ->
    document.addEventListener 'DOMContentLoaded', @createListeners
    document.addEventListener 'DOMContentLoaded', @initializeCamera
    document.addEventListener 'DOMContentLoaded', @getCoordinate
    document.addEventListener 'DOMContentLoaded', () ->
      document.getElementById("photoBooth").style.display="block"
      document.getElementById("gotoPhotoBooth").classList.add "selected"
    
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
    
    window.addEventListener "message", (event) =>
      clearInterval(@gmapInitMessage)
      if event.data.title is "latestCoordinates"
        @setStaticMap(event.data.content)
      return
    
    document.getElementById("closeLabelOverlay").addEventListener 'click', () =>
      $('#labelsManagerOverlay').fadeOut()
      return
      
    document.getElementById("newLabelButton").addEventListener 'click', () =>
      @addLabel()
      return
      
    document.getElementById("newLabelInput").addEventListener "keydown",(event) =>
      if event.keyCode is 13
        @addLabel()
      return
    
    document.getElementById("gotoLocation").addEventListener 'click', () =>
      @goto "location", "gotoLocation"
      return
    
    document.getElementById('gotoPhotoBooth').addEventListener 'click', () =>
      @initializeCamera()
      @goto "photoBooth", "gotoPhotoBooth"
      return
      
    document.getElementById('gotoValidation').addEventListener 'click', () =>
      @setupValidation()
      @goto "validation", "gotoValidation"
      return

    document.getElementById("closeSessionInfo").addEventListener 'click', () =>
      document.getElementById("closeSessionInfo").style.display = "none"
      @saveSessionInfoAndClose()
      return
    
    document.getElementById("closeAndIncognito").addEventListener 'click', () =>
      @sendMessage "background", {title:"toggleMem0r1es"}, () ->
        window.close()
      return
      
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
        labelSpan.setAttribute "class", "label labelHover"
        labelSpan.setAttribute "id", label.labelId
        labelSpan.appendChild document.createTextNode label.labelText
        labels.appendChild labelSpan
        labelSpan.addEventListener "click", (event) ->
          for selection in document.getElementsByClassName "label"
            selection.classList.remove "selected"
          event.target.classList.add "selected"
        ,false
        
      manageLabelLink = document.createElement "p"
      manageLabelLink.setAttribute "class", "manageLabelLink"
      manageLabelLink.appendChild document.createTextNode "manage labels"
      manageLabelLink.addEventListener "click", ()=>
        @generateLabelsManager()
        return
      ,false
      
      labels.appendChild manageLabelLink
      return
    
  generateLabelsManager: () =>
    labelsList = document.getElementById "labelsList"
    while labelsList.hasChildNodes()
      labelsList.removeChild labelsList.lastChild
      
    for label in @labels
      labelSpan = document.createElement "span"
      labelSpan.setAttribute "class", "label inEdit"
      labelSpan.setAttribute "id", label.labelId
      labelDeleteSpan = document.createElement "span"
      labelDeleteSpan.setAttribute "class", "labelDelete"
      labelDeleteSpan.setAttribute "title", "delete the label"
      labelDeleteSpan.setAttribute "id", label.labelId
      labelDeleteSpan.appendChild document.createTextNode "X"
      labelDeleteSpan.addEventListener "click", (event) =>
          @removeLabel parseInt(event.target.id, 10)
        ,false
      labelSpan.appendChild document.createTextNode label.labelText
      labelSpan.appendChild labelDeleteSpan
      labelsList.appendChild labelSpan
    $('#labelsManagerOverlay').fadeIn()

  goto: (step, menu) =>
    $(".pieceOfInfo").each () ->
      if $(this).attr('id') isnt step
        $(this).fadeOut()
      else
        
        $(this).fadeIn()
        
    $(".step").each () ->
      if $(this).attr('id') isnt menu
        $(this).removeClass "selected"
      else
        $(this).addClass "selected" 
  
  setupValidation : () =>
    finalPicHTML = document.getElementById("finalPic")
    finalPicHTML.src = @pic
    @label = @getSelectedLabel()
    
    if @label?
      document.getElementById("validationText").innerHTML="You are currently at <span class=\"label\">#{@label.labelText}</span>."
    else
      document.getElementById("validationText").innerHTML="<span class=\"warning\">Warning: You forgot to provide a label for your location. Go back to the <button id=\"goBackLocation\">2. location step</button> to select one.</span>"
      document.getElementById("goBackLocation").addEventListener "click", () =>
        @goto "location", "gotoLocation"
      
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
    for labelHTML in document.getElementsByClassName("label")
        if labelHTML.classList.contains("selected")
          for label in @labels
            if label.labelId is parseInt(labelHTML.id, 10)
              return label
    return undefined

  saveSessionInfoAndClose : () ->
    
    @sendMessage "userStudyToolbox", {title:"saveSession", content:{picture:@pic, location: @location, label: @label, timestamp: new Date().getTime()}}, (response) =>
      window.close()
    
sessionInfo = new mem0r1es.sessionInfo()