window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.DSLProcessor

  constructor : (@storageManager)->
    @initializer = setInterval () =>
      if @storageManager.isReady()
        @retrieveRules (DSRules) =>
          @DSRules = DSRules
          for rule in DSRules
            rule.includesRE = (new RegExp(include) for include in rule.includes)
            rule.excludesRE = (new RegExp(exclude) for exclude in rule.excludes)
          clearInterval @initializer
    ,100
      

    console.log "DSL processor ready"
  
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
        when "storeRule" then @storeRule message.content, sendResponse
        when "retrieveRules" then @retrieveRules sendResponse
        when "getRules" then @getRules sender.tab.url, sendResponse
        when "getRule" then @getRule message.content, sendResponse
        when "deleteRule" then @deleteRule message.content, sendResponse
    return
    
  storeRule : (rule, sendResponse) =>
    rule.includes = rule.includes.replace(" ","").split(",")
    rule.excludes = rule.excludes.replace(" ","").split(",")
    @storageManager.store "DSRules", rule, () =>
      @retrieveRules (DSRules) =>
        @DSRules = DSRules
        for rule in DSRules
          rule.includesRE = (new RegExp(include) for include in rule.includes)
          rule.excludesRE = (new RegExp(exclude) for exclude in rule.excludes)
      sendResponse()
    return
    
  retrieveRules : (sendResponse) ->
    query = new mem0r1es.Query().from("DSRules")
    @storageManager.get query, sendResponse
    return
    
  getRule : (messageContent, sendResponse) ->
    for rule in @DSRules
      if rule.ruleId is messageContent.ruleId
        sendResponse rule
    sendResponse {}
    return
    
  deleteRule : (messageContent, sendResponse) ->
    @storageManager.delete "DSRules", messageContent.ruleId, sendResponse
    return
    
  getRules : (url, sendResponse) ->
    console.log "getRules"
    appropriateRules = new Array()
    if @DSRules?
      for rule in @DSRules
        currentAppropriate = true
        for include in rule.includesRE
          if not url.match include
            currentAppropriate = false
        if currentAppropriate
          appropriateRules.push rule
    sendResponse appropriateRules
    return 