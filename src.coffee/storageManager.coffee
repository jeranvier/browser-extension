window.mem0r1es = {} if not window.mem0r1es?
window.indexedDB = window.indexedDB or window.webkitIndexedDB or window.mozIndexedDB or window.msIndexedDB
window.IDBTransaction = window.IDBTransaction or window.webkitIDBTransaction or window.mozIDBTransaction or window.msIDBTransaction

class window.mem0r1es.StorageManager

  constructor : () ->
    @queue = []
    @queueExecuting = false
    @SE = new mem0r1es.StorageExecutor
    @db = null
    @dbName = "mem0r1es"
    @version = 3
    @ready = false
    console.log "StorageManager ready"
  
  openDB : () ->
    request = indexedDB.open @dbName
    request.onsuccess = (event) =>
      @db = event.target.result
      @checkVersion()
      return
      
    request.onfailure = @onerror
    return
    
  checkVersion : () ->
    if parseInt(@version, 10) isnt parseInt(@db.version, 10)
      setVersionrequest = @db.setVersion @version
      setVersionrequest.onfailure = @onerror
      
      setVersionrequest.onsuccess = (event) =>
        console.log "creating/updating database #{@dbName}"
        if not @db.objectStoreNames.contains "temporary"
          temporary = @db.createObjectStore "temporary", { keyPath: "pageId" }
          #temporary.createIndex("b", "b", { unique: false })
          #temporary.createIndex("j", "j", { unique: false, multiEntry: true })
          
        if not @db.objectStoreNames.contains "parameters"
          parameters = @db.createObjectStore "parameters", { keyPath: "key" }
          
        if not @db.objectStoreNames.contains "labels"
          labels = @db.createObjectStore "labels", { keyPath: "labelId", autoIncrement: true }
          
        if not @db.objectStoreNames.contains "userStudySessions"
          userStudySessions = @db.createObjectStore "userStudySessions", { keyPath: "timestamp" }

        event.target.transaction.oncomplete = () =>
          console.log "database created/updated and ready"
          @SE.setDb @db
          @ready = true
          @executeQueue()
          return
          
        event.target.transaction.onerror = @onerror
          
        return
    else
      console.log "data store ready"
      @SE.setDb @db
      @ready = true
      @executeQueue()
    return
    
  onerror : () ->
    console.log "ERROR"
    
  #Handles messages received from background.js
  onMessage : (message, sender, sendResponse) ->
    console.log "message #{message.title}"
    switch(message.title)
      when "clearDB" then @clearDatabase sendResponse
      else console.log "Could not understand the command #{message.title}"
    return
    
  isReady : () ->
    return @ready
  
  executeQueue: () ->
    if @queueExecuting || not @ready
      return
    @queueExecuting = true
    
    while @queue.length isnt 0
      request = @queue.shift()
      request.method.apply @, request.arguments
    
    @queueExecuting = false
    return
  
  clearDatabase: (sendResponse)->
    @queue.push {method:@SE.clearDatabase, arguments:[sendResponse]}
    @executeQueue()
    return
  
  clearStore: (storeName) ->
    @queue.push {method:@SE.clearStore, arguments:[storeName]}
    @executeQueue()
    return
  
  store : (storeName, value, callback)->
    @queue.push {method:@SE.store, arguments:[storeName, value, callback]}
    @executeQueue()
    return
    
  get : (query, callback) ->
    @queue.push {method:@SE.get, arguments:[query, callback]}
    @executeQueue()
    return
  
  count : (storeName, callback) ->
    @queue.push {method:@SE.count, arguments:[storeName, callback]}
    @executeQueue()
    return
      
  delete : (storeName, id, callback) ->
    @queue.push {method:@SE.delete, arguments:[storeName, id, callback]}
    @executeQueue()
    return
      
  deleteDB : () ->
    @queue.push {method:@SE.deleteDB, arguments:[]}
    @executeQueue()
    return

