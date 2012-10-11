describe 'storageManager tests', ->
  storageManager = new mem0r1es.StorageManager
  
  beforeEach ()->
    runs ()->
      storageManager.openDB()
    return
    
  afterEach ()->
    waitsFor () ->
      return storageManager.isReady()
    , "DB was not ready in time", 10000
    runs ()->
      storageManager.deleteDB()
      return
    return

  it 'is ready', ->
    waitsFor () ->
      return storageManager.isReady()
    , "DB was not ready in time", 10000
    
    runs ()->
      expect(storageManager.isReady()).toBeTruthy()
      return
    return
  return