window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.inspector

  constructor : () ->
    @setupAngular()
    console.log "Mem0r1es Inspector ready"
    
  setupAngular : () ->
    @inspector = angular.module 'mem0r1esInspector', [], () ->
      return
    
    @createControllers()
    return
    
  createControllers : () =>
    @inspector.controller 'controller',['$scope','$q',(scope, q)=>
      delay = q.defer()
      scope.results = delay.promise
      @sendMessage "userStudyToolbox", {title:"getMem0r1es", content:""}, (results)=>
        for result in results
          console.log result
          if result.screenshot?
            result.screenshot = result.screenshot[0].screenshot
          else
            result.screenshot = ""
          d = new Date(result.timestamp)
          result.date = "#{d.getDate()}/#{d.getMonth()}/#{d.getFullYear()} - #{d.getHours()}:#{d.getMinutes()}"
          result.title = @getPageTitle result.DOM
          result.sessionPicture = ""
          result.sessionLocation = ""
          if result.userStudySession?
            result.sessionPicture = result.userStudySession.picture
            latitude = result.userStudySession.location.latitude
            longitude = result.userStudySession.location.longitude
            result.sessionLocation = "http://maps.googleapis.com/maps/api/staticmap?center=#{latitude},#{longitude}&zoom=18&size=450x338&maptype=hybrid&markers=color:red%7Clabel:Z%7C#{latitude},#{longitude}&sensor=false"
        scope.$apply () =>
          delay.resolve results
    ]
  
  getPageTitle : (DOM) ->
    if DOM.tag? and DOM.tag is "title"
      return DOM.text
      
    for child in DOM.children
      title = @getPageTitle child
      if title isnt false
        return title
    return false
    
  sendMessage : (module, message, callback)->
    if chrome.extension? 
      chrome.extension.sendMessage {module:module, message:message},(response)->
        if callback?
          callback response
        return
    return
  
inspector = new mem0r1es.inspector()