window.mem0r1es = {} if not window.mem0r1es?
window.requestFileSystem  = window.requestFileSystem || window.webkitRequestFileSystem
class window.mem0r1es.UserStudyToolbox

  constructor : (@storageManager, @idleInterval)->
    @sessionPageDisplayed = 0
    @browserState = "active"
    @currentCount = 0
    @totalCount = -1
    @chunkSize = 1000*1000*10
    @initLastDump()
    @dumpServerURL = "http://127.0.0.1:8080/"
    @checkIfNeedNewContext()
    @setupIdleListener()
    chrome.windows.onCreated.addListener () =>
      @checkIfFirstWindow()
    #@dumpDailyData()
    console.log "Toolbox for the user study is ready"

  initLastDump : () ->
    lastDump = localStorage.getItem 'lastDump'
    if not lastDump?
      localStorage.setItem 'lastDump', 0

  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
        when "addLabel" then @addLabel message.content, sendResponse
        when "setSessionPageDisplayed" then @setSessionPageDisplayed message.content, sendResponse
        when "deleteLabel" then @deleteLabel message.content, sendResponse
        when "retrieveLabels" then @retrieveLabels sendResponse
        when "saveSession" then @saveSession message.content, sendResponse
        when "newActivity" then @checkIfNeedNewContext sendResponse
        when "countDumpedData" then @countDumpedData sendResponse
        when "dumpData" then @dumpData sendResponse
        when "getDumpURL" then @getDumpURL sendResponse
        when "storeMem0r1esFile" then @storeMem0r1esFile message.content, sendResponse
        when "getMem0r1es" then @getMem0r1es message.content, sendResponse
        when "countMem0r1es" then @countMem0r1es sendResponse
        when "processFile" then @processFile message.content, sendResponse
        when "storeIncognitoSession" then @storeIncognitoSession message.content, sendResponse
    return

  setupIdleListener : () =>
    @IdleListenerInterval = setInterval () =>
      chrome.idle.queryState @idleInterval, (newState) =>
        if @browserState isnt newState
          console.log "User state switched from #{@browserState} to #{newState}"
          @browserState = newState
          if @browserState is "active" #need for a new session picture
            @onMessage {title:"newActivity"}, @, () ->
              console.log response
    ,5*1000 #every 5 sec we check

  #check, when a new window is added, if this is the first window.
  # this is a workaround so that the background services of chrome doesn't mess up
  # with the session detection
  checkIfFirstWindow: () =>
    chrome.windows.getAll {populate:false}, (windows) =>
      console.log "number of windows opened: #{windows.length}"
      if windows.length == 1
        @checkIfNeedNewContext()
      return

  setSessionPageDisplayed : (messageContent, sendResponse) =>
    @sessionPageDisplayed = messageContent.value
    console.log "setSessionPageDisplayed to #{messageContent.value}"
    return

  addLabel : (messageContent, sendResponse) =>
    @storageManager.store "labels", messageContent.label, () =>
      @retrieveLabels sendResponse
    return

  deleteLabel : (messageContent, sendResponse) =>
    @storageManager.delete "labels", messageContent.labelId, () =>
      @retrieveLabels sendResponse
    return

  retrieveLabels : (sendResponse) ->
    query = new mem0r1es.Query().from("labels")
    @storageManager.get query, sendResponse
    return

  saveSession : (messageContent, sendResponse) =>
    @sessionPageDisplayed = false
    @storageManager.store "userStudySessions", messageContent, () =>
      @updateLastActivityTime()
      localStorage.setItem 'lastUserStudySessionId', messageContent.userStudySessionId
      sendResponse()
    return

  updateLastActivityTime : () ->
    lastActivityTime = new Date().getTime()
    localStorage.setItem 'lastActivityTime', lastActivityTime
    return lastActivityTime

  getLastActivityTime : () ->
    lastActivityTime = localStorage.getItem 'lastActivityTime'
    if lastActivityTime is null
      localStorage.setItem 'lastActivityTime', 0
      return 0
    return lastActivityTime

  checkIfNeedNewContext : () ->
    console.log "is there already a session page displayed: #{@sessionPageDisplayed}"
    if not @sessionPageDisplayed
      chrome.tabs.create {'url': chrome.extension.getURL('html/sessionInfo.html'), pinned:true}
      @sessionPageDisplayed = true

  countDumpedData : (sendResponse) ->
    if @totalCount<0
      sendResponse 0.01
    else
      console.log "dump: #{@currentCount*100/@totalCount}"
      sendResponse @currentCount*100/@totalCount

  dumpDailyData : () =>
    lastDump = parseInt(localStorage.getItem('lastDump'), 10)
    @now = new Date().getTime()
    if @now < lastDump + 1000*60*60*24
      console.log "no dump needed"
      return
    else
      console.log "dumping the latest data"
    query = new mem0r1es.Query().from("temporary").where("timestamp", "between", lastDump, true , @now, false).getChildren [{name:"userAction", objectStore:"userActions"},{name:"screenshot", objectStore:"screenshots"}]
    @storageManager.get query, (results) =>
      console.log "dumping #{results.length} pages"
      if results.length > 50
        console.log "number of pages too important to be dumped remotely"
        return
      if results.length > 0
        page = results.shift()
      else
        page = null
      @tidyDumpUp page, results, {}, @sendToServer
    return

  tidyDumpUp : (page, results, dump, callback) =>

    if not page?
      query = new mem0r1es.Query().from("userStudySessions").where("userStudySessionId", "equals", "incognitoSessions")
      @storageManager.get query, (results) =>
        if results.length is 1
          dump[results[0].userStudySessionId] = {userStudySession : results[0]}
        callback dump
      return

    if dump[page._userStudySessionId]?
      dump[page._userStudySessionId].pages.push page
      if results.length > 0
        page = results.shift()
      else
        page = null

      @tidyDumpUp page, results, dump, callback
    else
      query = new mem0r1es.Query().from("userStudySessions").where("userStudySessionId", "equals", parseInt(page._userStudySessionId, 10))
      @storageManager.get query, (subResults) =>
        dump[page._userStudySessionId] = {}
        dump[page._userStudySessionId].userStudySession = subResults[0]
        dump[page._userStudySessionId].pages = []
        dump[page._userStudySessionId].pages.push page
        if results.length > 0
          page = results.shift()
        else
          page = null

        @tidyDumpUp page, results, dump, callback

  sendToServer : (dump) =>
    formData = new FormData()
    formData.append "dump", JSON.stringify(dump)

    xmlhttp = new XMLHttpRequest()
    xmlhttp.open "POST", @dumpServerURL, true
    xmlhttp.send(formData)
    xmlhttp.onreadystatechange = () =>
      if (xmlhttp.readyState isnt 4)
        return
      if (xmlhttp.status is 200)
        console.log "dump done."
        localStorage.setItem 'lastDump', @now

  dumpData : (sendResponse) =>
    console.log "dumping data for user study"
    query = new mem0r1es.Query().from("temporary").getChildren [{name:"userAction", objectStore:"userActions"},{name:"screenshot", objectStore:"screenshots"}]
    @storageManager.get query, (results) =>
      console.log "dumping #{results.length} pages"
      page = results.shift()
      @tidyDumpUp page, results, {}, @writeToDisk
    return

  writeToDisk : (dump) =>
    @currentCount=0
    window.requestFileSystem window.TEMPORARY, 1024*1024*1024, (@fs)=>
      @fs.root.getFile 'dump.json', {create: true}, (fileEntry)=>

        fileEntry.remove ()=>
          console.log "file removed"
          @fs.root.getFile 'dump.json', {create: true}, (fileEntry)=>
            console.log fileEntry.toURL()
            @DumpURL = fileEntry.toURL()
            stringifiedDump = JSON.stringify(dump)
            @totalCount = stringifiedDump.length/@chunkSize
            @writeNextChunk stringifiedDump
          , (e) ->
            console.log "Cannot write file to disk"
          return
        , (e) ->
        console.log "Cannot delete file to disk"
      return
    return

  getDumpURL : (sendResponse) =>
    sendResponse @DumpURL

  writeNextChunk : (remainingDump) =>
    if remainingDump.length is 0
      return

    if remainingDump.length > @chunkSize
      chunk = remainingDump.substring(0,@chunkSize)
      remainingDump = remainingDump.substring(@chunkSize)
    else
      chunk = remainingDump
      remainingDump = ""
    @fs.root.getFile 'dump.json', {create: false}, (fileEntry)=>
            fileEntry.createWriter (fileWriter)=>

              fileWriter.onwriteend = (e) =>
                @currentCount++
                @writeNextChunk remainingDump

              fileWriter.onerror  = (e) =>
                console.log e
              blob = new Blob [chunk]
              fileWriter.seek(fileWriter.length)
              fileWriter.write(blob)
            return
          , (e) ->
            console.log "Cannot write file to disk"
          return
        return
    return

  processFile : (messageContent, sendResponse) =>
    @storageManager.clearStore "temporary"
    @storageManager.clearStore "userStudySessions"
    @storageManager.clearStore "userActions"
    @storageManager.clearStore "screenshots"
    window.requestFileSystem window.TEMPORARY, 1024*1024, (fs)=>
      fs.root.getFile messageContent, {create: true}, (fileEntry)=>
        fileEntry.file (file) =>
          reader = new FileReader()

          reader.onload = (e) =>

            bufView = new Uint8Array(e.target.result)
            e.target.result=null
            bufString = new Array()
            for byte in bufView
              bufString.push String.fromCharCode(byte)
            bufView=null
            try
              mem0ries = JSON.parse bufString.join("")
            catch error
              sendResponse "Invalid json"
            count=0
            for key, session of mem0ries
              if session.pages?
                for page in session.pages
                  count++

            for key, session of mem0ries
              @storageManager.store "userStudySessions", session.userStudySession
              if session.pages?
                for page in session.pages
                  @storageManager.store "temporary", page, () =>
                    count--
                    if count is 0
                      sendResponse "Mem0r1es Loaded"

          reader.onerror = (event) =>
            console.error event.target.error.code
            sendResponse "Cannot read file"

          reader.readAsArrayBuffer(file)
        , (e) ->
          sendResponse "Cannot read file"
      , (e) ->
        sendResponse "Cannot open file"
    , (e) ->
      sendResponse "Cannot access file system"


  countMem0r1es : (sendResponse) =>
    query = new mem0r1es.Query().from("temporary")
    @storageManager.count query, (results) =>
      sendResponse results

  getMem0r1es : (messageContent, sendResponse) ->
    query = new mem0r1es.Query().from("temporary").where("timestamp","greaterThan",0).getChildren([{name:"screenshot", objectStore:"screenshots"}, {name:"userActions", objectStore:"userActions"}]).limit messageContent.limitMin, messageContent.limitMax
    @storageManager.get query, (results) =>
      count = results.length
      for result in results
        do(result) =>
          query = new mem0r1es.Query().from("userStudySessions").where("userStudySessionId", "equals", parseInt(result._userStudySessionId, 10))
          @storageManager.get query, (subResults) =>
            result.userStudySession = subResults[0]
            if count is 1
              sendResponse results
            else
              count--

  storeIncognitoSession : (messageContent, sendResponse) =>
    query = new mem0r1es.Query().from("userStudySessions").where("userStudySessionId", "equals", "incognitoSessions")
    @storageManager.get query, (results) =>
      if results.length is 1
        incognitoSessions = results[0]
      else
        incognitoSessions ={userStudySessionId: "incognitoSessions", sessions: new Array()}

      if messageContent.status is "start"
        incognitoSessions.sessions.push {start: messageContent.timestamp, browserStates: new Array()}
      else if messageContent.status is "end"
        incognitoSessions.sessions[incognitoSessions.sessions.length-1].end = messageContent.timestamp
      else
        incognitoSessions.sessions[incognitoSessions.sessions.length-1].browserStates.push {browserState: messageContent.status, timestamp: messageContent.timestamp}

      @storageManager.store "userStudySessions", incognitoSessions, ()=>
        sendResponse "incognitoSessions updated"
