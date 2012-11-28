window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.DSLProcessor

  constructor : (@storageManager)->
    @retrieveRules (results) =>
      if results.length is 1
        @DSRules = results[0].value
      else
        @DSRules = {}
      for ruleId, rule of @DSRules
        rule.includesRE = (new RegExp(include) for include in rule.includes)
        rule.excludesRE = (new RegExp(exclude) for exclude in rule.excludes)      
      console.log "DSL processor ready"
  
  onMessage : (message, sender, sendResponse) ->
    switch(message.title)
        when "storeRule" then @storeRule message.content, sendResponse
        when "getRulesForURL" then @getRulesForURL sender.tab.url, sendResponse
        when "getSpecificRule" then @getSpecificRule message.content, sendResponse
        when "getAllRules" then @getAllRules sendResponse
        when "deleteRule" then @deleteRule message.content, sendResponse
    return
  
  storeRule : (rule, sendResponse) =>
    rule.includes = rule.includes.replace(" ","").split(",")
    rule.excludes = rule.excludes.replace(" ","").split(",")
    @DSRules[rule.ruleId] = rule
    @storeRules sendResponse
    return
  
  #store every local rules in the indexedDB
  storeRules : (sendResponse) =>
    for ruleId, rule of @DSRules
      delete rule.includesRE
      delete rule.excludesRE
    @storageManager.store "parameters", {key : "DSRules", value: @DSRules}, () =>
      @retrieveRules (results) =>
        if results.length is 1
          @DSRules = results[0].value
        else
          @DSRules = {}
        for ruleId, rule of @DSRules
          rule.includesRE = (new RegExp(include) for include in rule.includes)
          rule.excludesRE = (new RegExp(exclude) for exclude in rule.excludes)
      sendResponse()
      return
    return
      
  retrieveRules : (sendResponse) ->
    query = new mem0r1es.Query().from("parameters").where("key", "equals", "DSRules")
    @storageManager.get query, sendResponse
    return
    
  getSpecificRule : (messageContent, sendResponse) ->
    for ruleId, rule of @DSRules
      if rule.ruleId is messageContent.ruleId
        sendResponse rule
        return
    sendResponse {}
    return
    
  deleteRule : (messageContent, sendResponse) ->
    delete @DSRules[messageContent.ruleId]
    @storeRules () ->
      sendResponse {id:messageContent.ruleId, status:"deleted"}
    return
    
  getAllRules : (sendResponse) ->
    sendResponse(@DSRules)
    
  getRulesForURL : (url, sendResponse) ->
    console.log "getRulesForURL"
    appropriateRules = new Array()
    if @DSRules?
      for ruleId, rule of @DSRules
        currentAppropriate = true
        for include in rule.includesRE
          if not url.match include
            currentAppropriate = false
        if currentAppropriate
          appropriateRules.push rule
    sendResponse appropriateRules
    return 