window.mem0r1es = {} if not window.mem0r1es?
window.indexedDB = window.indexedDB or window.webkitIndexedDB or window.mozIndexedDB or window.msIndexedDB
window.IDBTransaction = window.IDBTransaction or window.webkitIDBTransaction or window.mozIDBTransaction or window.msIDBTransaction

class window.mem0r1es.StorageManager

  constructor : () ->
    @db = null
    @dbName = "mem0r1es"
    @version = 2
    @ready = false
  
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
        
        if not @db.objectStoreNames.contains "consolidated"
          consolidated = @db.createObjectStore "consolidated", { keyPath: "pageId" }
          
        if not @db.objectStoreNames.contains "DSRules"
          DSRules = @db.createObjectStore "DSRules", { keyPath: "ruleId" }
          
        if not @db.objectStoreNames.contains "labels"
          labels = @db.createObjectStore "labels", { keyPath: "labelId", autoIncrement: true }
          
        if not @db.objectStoreNames.contains "userStudySessions"
          userStudySessions = @db.createObjectStore "userStudySessions", { keyPath: "timestamp" }

        event.target.transaction.oncomplete = () =>
          console.log "database created/updated and ready"
          @ready = true
          return
          
        event.target.transaction.onerror = @onerror
          
        return
    else
      console.log "data store ready"
      @ready = true
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
  
  clearDatabase: (sendResponse)->
    @clearStore "temporary"
    @clearStore "consolidated"
    @clearStore "DSRules"
    @clearStore "labels"
    sendResponse {message:{title:"message from networkManager", content:"Database cleared", level:"success"}}
  
  #Clears all the data from a specific store and send an ack to the popup
  #Argument: the methode used to respond to the popup
  clearStore: (storeName) ->
    if not @isReady
      return false
      
    trans = @db.transaction [storeName], "readwrite"
    store = trans.objectStore storeName
    
    if store?
      clearReq = store.clear()
      
      clearReq.onsuccess = (event) ->
        console.log "#{storeName} cleared"
        return
        
      clearReq.onerror = (event) ->
        console.log "error while clearing #{storeName}"
        return
        
      return
  
  #Stores an object corresponding to a page browsing in the datastore
  # callback is optional and is here to notify the caller that the object has been successfully inserted
  store : (storeName, value, callback)->
    trans = @db.transaction [storeName], "readwrite"
    store = trans.objectStore storeName
    request = store.put value
    
    request.onsuccess = (event) ->
      #console.log "#{value} [STORED]"
      if callback?
        try
          callback event.target.result
        catch error
      return
    
    request.onerror = @onerror
    
    return
    
  get : (query, callback) ->
    results = new Array
    trans = @db.transaction [query.storeName], "readonly"
    store = trans.objectStore query.storeName
    try
      index = store.index query.key
    catch error
    if not index?
      index = store
    if query.keyRange
      request = index.openCursor(query.keyRange)
    else
      request = index.openCursor()
    request.onsuccess = (event) ->
      cursor = event.target.result
      if cursor?
        if query.accept cursor.value
          results.push cursor.value
        cursor.continue()
      else
        callback results
    return
  
  count : (storeName, callback) ->
    trans = @db.transaction [storeName], "readonly"
    store = trans.objectStore storeName
    request = store.count()
    request.onsuccess = (event) ->
      callback event.target.result
      
  delete : (storeName, id, callback) ->
    console.log "deleting object with PK #{id} from #{storeName}"
    trans = @db.transaction [storeName], "readwrite"
    store = trans.objectStore storeName
    request = store.delete id
    request.onsuccess = (event) ->
      callback {id : id, status: "deleted"}
      
  deleteDB : () ->
    @db.close()
    request = indexedDB.deleteDatabase @dbName
    request.onsuccess = () =>
      console.log "database #{@dbName} deleted"
      return
    return

