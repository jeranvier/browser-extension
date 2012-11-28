window.mem0r1es = {} if not window.mem0r1es?
window.indexedDB = window.indexedDB or window.webkitIndexedDB or window.mozIndexedDB or window.msIndexedDB
window.IDBTransaction = window.IDBTransaction or window.webkitIDBTransaction or window.mozIDBTransaction or window.msIDBTransaction

class window.mem0r1es.StorageExecutor  

  setDb: (@db) ->
    console.log "Storage executor ready"
    
  onerror : () ->
    console.log "ERROR"
  
  clearDatabase: (sendResponse)->
    @clearStore "temporary"
    @clearStore "parameters"
    @clearStore "labels"
    @clearStore "userStudySessions"
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

