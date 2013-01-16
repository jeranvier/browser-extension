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
      editRuleLink = document.createElement "a"
      editRuleLink.className = "btn"
      editRuleLink.id = "edit_rule#{rule.ruleId}"
      editRuleLink.addEventListener 'click', () ->
        mem0r1es.options.editRule parseInt(@id.substring(9),10)
      editRuleLinkIcon = document.createElement "i"
      editRuleLinkIcon.className = "icon-edit"
      editRuleLink.appendChild editRuleLinkIcon
      
      deleteRuleLink = document.createElement "a"
      deleteRuleLink.className = "btn"
      deleteRuleLink.id = "delete_rule#{rule.ruleId}"
      deleteRuleLink.addEventListener 'click', () ->
        mem0r1es.options.deleteRule parseInt(@id.substring(11),10)
      deleteRuleLinkIcon = document.createElement "i"
      deleteRuleLinkIcon.className = "icon-trash"
      deleteRuleLink.appendChild deleteRuleLinkIcon
      
      name.appendChild(document.createTextNode rule.name)
      includes.appendChild(document.createTextNode rule.includes)
      excludes.appendChild(document.createTextNode rule.excludes)
      functions.appendChild(document.createTextNode rule.exec)

      actions.appendChild editRuleLink
      actions.appendChild deleteRuleLink
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
      message.className = "text-warning text-centered"
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
    $('#ruleForm').modal('show')
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
    $('#ruleForm').modal('hide')
    mem0r1es.options.displayRules()

mem0r1es.options.initializeRules = () ->
  document.getElementById('addDSRuleLink').addEventListener 'click', () ->
    document.getElementById("ruleId").value = ""
    document.getElementById("name").value = ""
    document.getElementById("includes").value = ""
    document.getElementById("excludes").value = ""
    document.getElementById("exec").value = ""
  document.getElementById('saveRule').addEventListener 'click', mem0r1es.options.saveRule
  mem0r1es.options.displayRules()

mem0r1es.options.initializeOptions = () ->
  mem0r1es.options.initializeRules()
  document.getElementById('dropBox').addEventListener "drop", mem0r1es.onDropMemories
  document.addEventListener "dragover", (event) ->
    event.preventDefault() #Chrome 24.x.x introduces a behavior that places the default action (open file) above customed drag n drop directives.
    
  document.getElementById('extractUserStudyLink').addEventListener 'click', () =>
    $("#extractUserStudyLink").button 'loading'
    $("#downloadDumpLink").fadeOut()
    mem0r1es.options.sendMessage "userStudyToolbox", {title: "countDumpData"},(totalCount) =>
      $("#dumpProgress").fadeIn()
      mem0r1es.updateProgressBar totalCount
        
      mem0r1es.options.sendMessage "userStudyToolbox", {title: "dumpData"}, (dump) =>
        #xmlhttp=new XMLHttpRequest()
        #xmlhttp.open "POST", "http://127.0.0.1:8080/", true
        #xmlhttp.setRequestHeader "Content-type", "application/json"
        #xmlhttp.send(JSON.stringify(dump))
        blob = new Blob [JSON.stringify(dump)], {type: 'application/json'}
        downloadDumpLink = document.getElementById("downloadDumpLink")
        downloadDumpLink.href = window.webkitURL.createObjectURL blob
  return

mem0r1es.updateProgressBar = (totalCount) =>
    mem0r1es.options.sendMessage "userStudyToolbox", {title: "countDumpedData"},(currentCount) =>
      console.log "#{currentCount} / #{totalCount}"
      ratio = currentCount*100/totalCount
      $("#dumpProgressBar").width "#{ratio}%"
      if ratio == 100
        $("#downloadDumpLink").fadeIn()
        $("#extractUserStudyLink").button 'reset'
      else
        setTimeout () ->
          mem0r1es.updateProgressBar totalCount
        ,1000

mem0r1es.onDropMemories = (event) ->
  files = event.dataTransfer.files
  count = files.length;
  for file in files
    mem0r1es.handleMem0r1esFile file
  event.preventDefault()

mem0r1es.handleMem0r1esFile = (file) =>
  reader = new FileReader()
  reader.onload = (fileLoadedEvent) =>
    $('#dropBoxText').text "Mem0r1es Loading..."
    mem0r1es.options.sendMessage "userStudyToolbox", {title: "storeMem0r1esFile", content:fileLoadedEvent.target.result}, (response) =>
      $('#dropBoxText').text response
    
  reader.readAsText file
document.addEventListener 'DOMContentLoaded', mem0r1es.options.initializeOptions