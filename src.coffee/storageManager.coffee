window.mem0r1es = {} if not window.mem0r1es?
window.indexedDB = window.webkitIndexedDB
window.IDBTransaction = window.webkitIDBTransaction
window.IDBKeyRange =window.webkitIDBKeyRange

class window.mem0r1es.StorageManager
  @db=null
  @version=null
  @ready=false
  
  openDB: () ->
    request = indexedDB.open "mem0r1es"
    request.onsuccess = (event) =>
      @db = event.target.result
      @version = 2
      @checkVersion()
      @ready = true
      return
      
    request.onfailure = @onerror
    return
    
  checkVersion : () ->
    if parseInt(@version, 10) isnt parseInt(@db.version, 10)
      setVersionrequest = @db.setVersion @version
      setVersionrequest.onfailure = @onerror;
      
      setVersionrequest.onsuccess = (event) =>
        console.log "creating/updating data store"
        temporary = @db.createObjectStore "temporary", { autoIncrement: true }
        consolidated = @db.createObjectStore "consolidated", { autoIncrement: true }
        #store.createIndex("abc", "abc", { unique: false })
        
        event.target.transaction.oncomplete = () ->
          console.log "data store created"
          return
          
        event.target.transaction.onerror = @onerror
          
        return
        
    else
      console.log "data store ready"
      
    return
    
  onerror : () ->
    console.log "ERROR"
    
  #Handles messages received from background.js
  onMessage : (message, sendResponse) ->
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
  store : (storeName, value)->
    trans = @db.transaction [storeName], "readwrite"
    store = trans.objectStore storeName
    request = store.put value
    
    request.onsuccess = (event) ->
      console.log "#{value} [STORED]"
      return
    
    request.onerror = @onerror
    
    return
    
  get : (storeName, key, value, callback) ->
    result = new Array
    singleKeyRange = IDBKeyRange.only value
    trans = @db.transaction [storeName], "readonly"
    store = trans.objectStore storeName
    index = store.index key
    
    index.openCursor(singleKeyRange).onsuccess = (event) ->
      cursor = event.target.result
      if cursor?
        results[results.length] = cursor.value
        cursor.continue
      else
        callback results
      return
    return