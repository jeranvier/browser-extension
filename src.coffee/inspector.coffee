window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.inspector

  constructor : () ->
    @setupAngular()
    console.log "Mem0r1es Inspector ready"
    
  setupAngular : () ->
    @createControllers()
    angular.module "mem0r1esInspector", ["mem0r1esInspector.controller"]
    
  createControllers : () ->
    angular.module("mem0r1esInspector.controller",[]).controller 'mem0r1esController',['$scope',(scope)->
      scope.mem0r1es = [
        {"id": "id1","URL": "http://www.example1.com"}
        {"id": "id2","URL": "http://www.example2.com"}
        {"id": "id3","URL": "http://www.example3.com"}
      ]
    ]

inspector = new mem0r1es.inspector()