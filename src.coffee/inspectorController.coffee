window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.InspectorController

  constructor : (@scope, @q) ->
    @scope.loadData = (page) =>
      $(".pages").removeClass "active "
      $("#page_#{page.page}").addClass "active "
      @loadData(page.limitMin, page.limitMax)
    @step = 10
    console.log "Mem0r1es InspectorController ready"
    @getCount()
    @loadData 0, @step
  
  getCount : () =>
    @sendMessage "userStudyToolbox", {title:"countMem0r1es", content:""}, (results)=>
      @scope.$apply () =>
        int = [1..Math.ceil(results/@step)]
        @scope.count = []
        for i in int
          @scope.count[i-1] = {page:i, limitMin:(i-1)*@step, limitMax:(i)*@step}

        
  loadData : (limitMin, limitMax) =>
    delay = @q.defer()
    @scope.results = delay.promise
    @sendMessage "userStudyToolbox", {title:"getMem0r1es", content:{limitMin:limitMin, limitMax: limitMax}}, (results)=>
      for result in results
        if result.screenshot isnt 'undefined' and result.screenshot.length is 1 and result.screenshot[0].screenshot isnt 'undefined'
          result.screenshot = result.screenshot[0].screenshot
        else
          result.screenshot = ""
        d = new Date(result.timestamp)
        result.date = "#{d.getDate()}/#{d.getMonth()+1}/#{d.getFullYear()} - #{d.getHours()}:#{d.getMinutes()}"
        result.title = @getPageTitle result.DOM
        result.sessionPicture = ""
        result.sessionLocation = ""
        
        if result.userStudySession?
          result.sessionPicture = result.userStudySession.picture
          latitude = result.userStudySession.location.latitude
          longitude = result.userStudySession.location.longitude
          result.sessionLocation = "http://maps.googleapis.com/maps/api/staticmap?center=#{latitude},#{longitude}&zoom=18&size=450x338&maptype=hybrid&markers=color:red%7Clabel:Z%7C#{latitude},#{longitude}&sensor=false"
        
        lastFocus = parseInt(result.focusTime[result.focusTime.length-1].timestamp ,10)
        lastActivity= parseInt(result.activityTime[result.activityTime.length-1].timestamp ,10)
        if lastFocus < lastActivity
          result.exitTimestamp = lastActivity + 10000
        else
          result.exitTimestamp = lastFocus + 10000
          
        for userAction in result.userActions
          if userAction.type is "unload"
            result.exitTimestamp = userAction.timestamp
            break
            
        result.timeSpentOnThePage = result.exitTimestamp - result.timestamp
        
      @scope.$apply () =>
        delay.resolve results
  
  getPageTitle : (DOM) ->
    if DOM.tag? and DOM.tag is "title"
      return DOM.text
      
    for child in DOM.children
      title = @getPageTitle child
      if title isnt false
        return title
    return false
    
  sendMessage : (module, message, callback)->
    if chrome.extension?
      chrome.extension.sendMessage {module:module, message:message},(response)->
        if callback?
          callback response
        return
    return
