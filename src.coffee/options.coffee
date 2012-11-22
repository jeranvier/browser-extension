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
  mem0r1es.options.sendMessage "DSLProcessor", {title: "retrieveRules"}, (results) ->
    rulesBodyNode = document.getElementById "rulesBody"
    
    while rulesBodyNode.hasChildNodes()
      rulesBodyNode.removeChild(rulesBodyNode.lastChild);
      
    for rule in results
      ruleNode = document.createElement "tr"
      name = document.createElement "td"
      includes = document.createElement "td"
      excludes = document.createElement "td"
      functions = document.createElement "td"
      actions = document.createElement "td"
      editRuleButton = document.createElement "button"
      editRuleButton.className = "ruleAction"
      editRuleButton.id = "edit#{rule.ruleId}"
      editRuleButton.addEventListener 'click', () ->
        mem0r1es.options.editRule parseInt(@id.substring(4),10)
      deleteRuleButton = document.createElement "button"
      deleteRuleButton.className = "ruleAction"
      deleteRuleButton.id = "delete#{rule.ruleId}"
      deleteRuleButton.addEventListener 'click', () ->
        mem0r1es.options.deleteRule parseInt(@id.substring(6),10)
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

mem0r1es.options.editRule = (ruleId) ->
  mem0r1es.options.sendMessage "DSLProcessor", {title: "getRule", content:{ruleId: ruleId}}, (rule) ->
    document.getElementById("ruleId").value = ruleId
    document.getElementById("name").value = rule.name
    document.getElementById("includes").value = rule.includes
    document.getElementById("excludes").value = rule.excludes
    document.getElementById("exec").value = rule.exec
    document.getElementById('overlay').style.display = "block";
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
      document.getElementById('overlay').style.display = "none";
    , 0
    mem0r1es.options.displayRules()

mem0r1es.options.initialize = () ->
  document.getElementById('save').addEventListener 'click', mem0r1es.options.saveRule
  document.getElementById('createButton').addEventListener 'click', () ->
    document.getElementById("ruleId").value = ""
    document.getElementById("name").value = ""
    document.getElementById("includes").value = ""
    document.getElementById("excludes").value = ""
    document.getElementById("exec").value = ""
    document.getElementById('overlay').style.display = "block";
  document.getElementById('cancel').addEventListener 'click', () ->
    document.getElementById('overlay').style.display = "none";
  document.getElementById('closeRuleOverlay').addEventListener 'click', () ->
    document.getElementById('overlay').style.display = "none";
  mem0r1es.options.displayRules()
  
document.addEventListener 'DOMContentLoaded', mem0r1es.options.initialize