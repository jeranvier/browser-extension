window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.Inspector

  constructor : () ->
    @setupAngular()
    console.log "Mem0r1es Inspector ready"
    
  setupAngular : () ->
    @inspector = angular.module 'mem0r1esInspector', [], () ->
      return
      
    @inspector.controller 'controller', ['$scope','$q', (scope, q)->
      return new mem0r1es.InspectorController(scope, q)
    ]
    
    @inspector.directive 'createFocusTimeline', () =>
      return (scope, element, attrs) =>
        timeline = new mem0r1es.Timeline element[0], mem0r1es.Timeline.processData(scope.result.focusTime,"focused", scope.result.exitTimestamp)
    
    @inspector.directive 'createActivityTimeline', () =>
      return (scope, element, attrs) =>
        timeline = new mem0r1es.Timeline element[0], mem0r1es.Timeline.processData(scope.result.activityTime,"active", scope.result.exitTimestamp)
        
    @inspector.directive 'prettifyDuration', () =>
      return (scope, element, attrs) =>
        timestamp = parseInt(scope.result[attrs.prettifyDuration],10)
        seconds = Math.floor(timestamp/1000)
        minutes = Math.floor(seconds/60)
        hours = Math.floor(minutes/60)
        days = Math.floor(hours/24)
        hours = hours - 24*days
        minutes = minutes - 60*hours - 24*days
        seconds = seconds - 60*minutes - 60*hours - 24*days
        string = ""
        if days isnt 0
          string = "#{string} #{days} days"
        if hours isnt 0
          string = "#{string} #{hours} hours"
        if minutes isnt 0
          string = "#{string} #{minutes} minutes"
        if seconds isnt 0
          string = "#{string} #{seconds} seconds"
        element[0].innerHTML = "#{string}"
        console.log scope.result[attrs.prettifyDuration]
    return
  
inspector = new mem0r1es.Inspector()