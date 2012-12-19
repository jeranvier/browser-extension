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
    return
  
inspector = new mem0r1es.Inspector()