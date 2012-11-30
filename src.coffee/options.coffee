window.mem0r1es = {} if not window.mem0r1es?
mem0r1es.options = {}

mem0r1es.options.sendMessage = (module, message, callback)->
  if chrome.extension? 
    chrome.extension.sendMessage {module:module, message:message},(response)->
      if callback?
        callback response
      return
  return
  
mem0r1es.options.displayRules = () ->
  mem0r1es.options.sendMessage "DSLProcessor", {title: "getAllRules"}, (DSRules) ->
    rulesBodyNode = document.getElementById "rulesBody"
    while rulesBodyNode.hasChildNodes()
      rulesBodyNode.removeChild(rulesBodyNode.lastChild);
    
    count = 0
    for ruleId, rule of DSRules
      count++
      ruleNode = document.createElement "tr"
      name = document.createElement "td"
      includes = document.createElement "td"
      excludes = document.createElement "td"
      functions = document.createElement "td"
      actions = document.createElement "td"
      editRuleButton = document.createElement "button"
      editRuleButton.className = "ruleAction floatRight"
      editRuleButton.id = "edit_rule#{rule.ruleId}"
      editRuleButton.addEventListener 'click', () ->
        mem0r1es.options.editRule parseInt(@id.substring(9),10)
      deleteRuleButton = document.createElement "button"
      deleteRuleButton.className = "ruleAction floatRight"
      deleteRuleButton.id = "delete_rule#{rule.ruleId}"
      deleteRuleButton.addEventListener 'click', () ->
        mem0r1es.options.deleteRule parseInt(@id.substring(11),10)
      name.appendChild(document.createTextNode rule.name)
      includes.appendChild(document.createTextNode rule.includes)
      excludes.appendChild(document.createTextNode rule.excludes)
      functions.appendChild(document.createTextNode rule.exec)
      editRuleButton.appendChild(document.createTextNode "edit")
      deleteRuleButton.appendChild(document.createTextNode "delete")
      actions.appendChild editRuleButton
      actions.appendChild deleteRuleButton
      ruleNode.appendChild name
      ruleNode.appendChild includes
      ruleNode.appendChild excludes
      ruleNode.appendChild functions
      ruleNode.appendChild actions
      rulesBodyNode.appendChild ruleNode
    
    if count is 0
      ruleNode = document.createElement "tr"
      message = document.createElement "td"
      message.setAttribute "colspan", "5"
      message.className = "centered"
      message.appendChild(document.createTextNode "No domain specific rules yet")
      ruleNode.appendChild message
      rulesBodyNode.appendChild ruleNode

mem0r1es.options.editRule = (ruleId) ->
  mem0r1es.options.sendMessage "DSLProcessor", {title: "getSpecificRule", content:{ruleId: ruleId}}, (rule) ->
    document.getElementById("ruleId").value = ruleId
    document.getElementById("name").value = rule.name
    document.getElementById("includes").value = rule.includes
    document.getElementById("excludes").value = rule.excludes
    document.getElementById("exec").value = rule.exec
    $("#overlay").fadeIn()
    $("#ruleForm").fadeIn()
    return
  return
  
mem0r1es.options.deleteRule = (ruleId) ->
  mem0r1es.options.sendMessage "DSLProcessor", {title: "deleteRule", content:{ruleId: ruleId}}, (result) ->
    if result.id is ruleId and result.status is "deleted"
      mem0r1es.options.displayRules()
    else
      alert "something went wrong while deleting the rule #{result.id}"
  return
      
mem0r1es.options.saveRule = () ->
  rule = {}
  if document.getElementById("ruleId").value is ""
    rule.ruleId = new Date().getTime()
  else
    rule.ruleId = parseInt(document.getElementById("ruleId").value,10)
  rule.name = document.getElementById("name").value
  rule.includes = document.getElementById("includes").value
  rule.excludes = document.getElementById("excludes").value
  rule.exec = document.getElementById("exec").value
  mem0r1es.options.sendMessage "DSLProcessor", {title: "storeRule", content: rule}, () ->
    status = document.getElementById "status"
    status.innerHTML = "Rules updated."
    setTimeout () ->
      status.innerHTML = ""
      $("#overlay").fadeOut()
    , 0
    mem0r1es.options.displayRules()

mem0r1es.options.initializeRules = () ->
  document.getElementById('saveRule').addEventListener 'click', mem0r1es.options.saveRule
  document.getElementById('createRuleButton').addEventListener 'click', () ->
    document.getElementById("ruleId").value = ""
    document.getElementById("name").value = ""
    document.getElementById("includes").value = ""
    document.getElementById("excludes").value = ""
    document.getElementById("exec").value = ""
    $("#overlay").fadeIn()
    $("#ruleForm").fadeIn()
  document.getElementById('cancelRule').addEventListener 'click', () ->
    $("#overlay").fadeOut()
    $("#ruleForm").fadeOut()
  document.getElementById('closeRuleOverlay').addEventListener 'click', () ->
    $("#overlay").fadeOut()
    $("#ruleForm").fadeOut()
  mem0r1es.options.displayRules()

mem0r1es.options.displayUserStudyWebsites = () ->
  mem0r1es.options.sendMessage "userStudyToolbox", {title: "getUserStudyWebsites"}, (websites) ->
    while userStudyWebsitesBody.hasChildNodes()
      userStudyWebsitesBody.removeChild(userStudyWebsitesBody.lastChild);
    
    count = 0
    for websiteId, website of websites
      count++
      websiteNode = document.createElement "tr"
      title = document.createElement "td"
      pattern = document.createElement "td"
      actions = document.createElement "td"
      deleteWebsiteButton = document.createElement "button"
      deleteWebsiteButton.className = "ruleAction floatRight"
      deleteWebsiteButton.id = "delete_website#{website.websiteId}"
      deleteWebsiteButton.addEventListener 'click', () ->
        mem0r1es.options.deleteWebsite parseInt(@id.substring(14),10)
      title.appendChild(document.createTextNode website.title)
      pattern.appendChild(document.createTextNode website.pattern)
      deleteWebsiteButton.appendChild(document.createTextNode "delete")
      actions.appendChild deleteWebsiteButton
      websiteNode.appendChild title
      websiteNode.appendChild pattern
      websiteNode.appendChild actions
      userStudyWebsitesBody.appendChild websiteNode
      
    if count is 0
      websiteNode = document.createElement "tr"
      message = document.createElement "td"
      message.setAttribute "colspan", "3"
      message.className = "centered"
      message.appendChild(document.createTextNode "No website selected for the study")
      websiteNode.appendChild message
      userStudyWebsitesBody.appendChild websiteNode
      
mem0r1es.options.deleteWebsite = (websiteId) ->
  mem0r1es.options.sendMessage "userStudyToolbox", {title: "deleteUserStudyWebsite", content:websiteId}, () ->
    mem0r1es.options.displayUserStudyWebsites()

mem0r1es.options.saveUserStudyWebsite = () ->
  website = {}
  website.title = document.getElementById("userWebsiteTitle").value
  website.pattern = document.getElementById("urlPattern").value
  website.websiteId = new Date().getTime()
  mem0r1es.options.sendMessage "userStudyToolbox", {title: "storeUserStudyWebsite", content:website}, () ->
    $("#overlay").fadeOut()
    $("#userStudyWebsiteForm").fadeOut()
    mem0r1es.options.displayUserStudyWebsites()
    
mem0r1es.options.initializeUserStudyWebsite = () ->
  document.getElementById('saveUserStudyWebsite').addEventListener 'click', mem0r1es.options.saveUserStudyWebsite
  document.getElementById('createUserStudyWebsiteButton').addEventListener 'click', () ->
    document.getElementById("userWebsiteTitle").value = ""
    document.getElementById("urlPattern").value = ""
    $("#overlay").fadeIn()
    $("#userStudyWebsiteForm").fadeIn()
  document.getElementById('cancelUserStudyWebsite').addEventListener 'click', () ->
    $("#overlay").fadeOut()
    $("#userStudyWebsiteForm").fadeOut()
  document.getElementById('closeUserStudyWebsiteOverlay').addEventListener 'click', () ->
    $("#overlay").fadeOut()
    $("#userStudyWebsiteForm").fadeOut()
  document.getElementById('extractUserStudyButton').addEventListener 'click', () ->
    mem0r1es.options.sendMessage "userStudyToolbox", {title: "dumpData"}, (dump) ->
        xmlhttp=new XMLHttpRequest()
        xmlhttp.open "POST", "http://127.0.0.1:8080/", true
        xmlhttp.setRequestHeader "Content-type", "application/json"
        xmlhttp.send(JSON.stringify(dump))
    
  mem0r1es.options.displayUserStudyWebsites()

mem0r1es.options.initializeOptions = () ->
  mem0r1es.options.initializeRules()
  mem0r1es.options.initializeUserStudyWebsite()
  return
  
document.addEventListener 'DOMContentLoaded', mem0r1es.options.initializeOptions