window.mem0r1es = {} if not window.mem0r1es?
window.mem0r1es.benchmark = {}
window.mem0r1es.benchmark.populated = false

window.mem0r1es.benchmark.storageManager = new mem0r1es.StorageManager

#Size of the tested population
window.mem0r1es.benchmark.cardinality = 100

#size of the population in the database at a certain moment of the insertion process (will be incremented to #{mem0r1es.benchmark.cardinality})
window.mem0r1es.benchmark.currentCardinality = 0

#generate a random string of #{length} characters
window.mem0r1es.benchmark.stringGenerator = (length) ->
  alphabet = [ 'a', 'b' ,'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', ' ', ',', '. ']
  string = ""
  for i in [0 .. length-1] by 1
    string = "#{string}#{alphabet[Math.floor(Math.random()*alphabet.length)]}"
  string = "#{string}."
  return string

#populate the database with #{mem0r1es.benchmark.cardinality} items
window.mem0r1es.benchmark.populate = () ->
  console.log "populating the database with #{mem0r1es.benchmark.cardinality} elements"
  for i in [0 .. mem0r1es.benchmark.cardinality-1] by 1
    data =
      'a': i
      'b': Math.floor(Math.random()*10)
      'c': Math.floor(Math.random()*10)
      'd': Math.floor(Math.random()*10)
      'e': Math.floor(Math.random()*10)
      'f': Math.floor(Math.random()*10)
      'g': mem0r1es.benchmark.stringGenerator 5
      'h': mem0r1es.benchmark.stringGenerator 5
      'i': mem0r1es.benchmark.stringGenerator 10
      'j': ["abc", "def"]
      'k': mem0r1es.benchmark.stringGenerator 2000
      'l': mem0r1es.benchmark.stringGenerator 2000
    mem0r1es.benchmark.storageManager.store "temporary", data, (result) ->
      mem0r1es.benchmark.currentCardinality++
  return

#############

beforeAll () ->
  console.log "Setup the test"
  mem0r1es.benchmark.storageManager.openDB()
  waitsFor () ->
    return mem0r1es.benchmark.storageManager.isReady()
  , () ->
    startPopulate = new Date().getTime()
    mem0r1es.benchmark.populate()
    waitsFor () ->
      mem0r1es.benchmark.currentCardinality is mem0r1es.benchmark.cardinality
    , () ->
      console.log "Time to generate items and populate the DB with #{mem0r1es.benchmark.cardinality} items : #{new Date().getTime() - startPopulate} ms"
      window.beforeAll_done = true

#############

describe 'IndexDB Fetching schemes', ->
 
  it 'fetch by index', ->
    start = new Date().getTime()
    runs () ->
      query = new mem0r1es.Query().from("temporary").where("b", "greaterThan", 5, true)
      mem0r1es.benchmark.storageManager.get query , (results) =>
        console.log "Time to run 'fetch by index' : #{new Date().getTime() - start} ms. retreived #{results.length} results"
        console.log results
        return
      return
    return
  
  it 'fetch by two indexes', ->
    start = new Date().getTime()
    runs () ->
      query = new mem0r1es.Query().from("temporary").where("b", "equals", 5).and("c", "greaterThan", 3)
      mem0r1es.benchmark.storageManager.get query, (results) =>
        console.log "Time to run 'fetch by index and 1 condition' : #{new Date().getTime() - start} ms. retreived #{results.length} results"
        console.log results
        return
      return
    return
    
  it 'fetch by three indexes', ->
    start = new Date().getTime()
    runs () ->
      query = new mem0r1es.Query().from("temporary").where("b", "equals", 5).and("c", "greaterThan", 3).and("d", "lowerThan", 8)
      mem0r1es.benchmark.storageManager.get query, (results) =>
        console.log "Time to run 'fetch by index and 2 conditions' : #{new Date().getTime() - start} ms. retreived #{results.length} results"
        console.log results
        return
      return
    return
    
  it 'fetch by PK', ->
    start = new Date().getTime()
    runs () ->
      query = new mem0r1es.Query().from("temporary").where("a", "greaterThan", 0)
      mem0r1es.benchmark.storageManager.get query, (results) =>
        console.log "Time to run 'fetch by primary key' : #{new Date().getTime() - start} ms. retreived #{results.length} results"
        console.log results
        return
      return
    return

  it 'fetch by array element', ->
    start = new Date().getTime()
    runs () ->
      query = new mem0r1es.Query().from("temporary").where("j", "equals", "def")
      mem0r1es.benchmark.storageManager.get query, (results) =>
        console.log "Time to run 'fetch by array element' : #{new Date().getTime() - start} ms. retreived #{results.length} results"
        console.log results
        return
      return
    return

  it 'delete everything', ->
    runs ()->
      mem0r1es.benchmark.storageManager.deleteDB()
      return
    return
  return

