var mem0r1es=mem0r1es || {};

mem0r1es.injectable = {};

mem0r1es.injectable.JSONDOM={};

mem0r1es.injectable.DOMtoJSON = function(node){
			
			var JSONNode = {};
			JSONNode.tag = node.nodeName.toLowerCase();
			
			//fetch node attributes
			var DOMAttributes = node.attributes;
			JSONNode.attributes = {};
			for (var i=0; i<DOMAttributes.length; i++) {
				JSONNode.attributes[DOMAttributes[i].name] = DOMAttributes[i].value;
			}
			
			if(DOMAttributes.length == 0){
				delete JSONNode.attributes;
			}			
			
			//recursively converte child nodes to json
			var DOMChildren = node.childNodes;
			JSONNode.children = new Array();
			for (var i=0; i<DOMChildren.length; i++) {
				if(DOMChildren[i].nodeType == 1){
					JSONNode.children[JSONNode.children.length] = mem0r1es.injectable.DOMtoJSON(DOMChildren[i]);
				}
				
				if(DOMChildren[i].nodeType == 3 && JSONNode.tag != "script" && DOMChildren[i].nodeValue.replace(/[\n\t]*/g,"").length !=0){
					JSONNode.text = DOMChildren[i].nodeValue.replace(/[\n\t]*/g,"");
				}
			}
			
			if(JSONNode.children.length == 0){
				delete JSONNode.children;
			}
			
			return JSONNode;
		}
		
/*Listen for message from background
 */		
chrome.extension.onMessage.addListener(
	function(request, sender, sendResponse) {
		if (request.query == "getJSONDOM"){
			mem0r1es.injectable.JSONDOM = mem0r1es.injectable.DOMtoJSON(document.getElementsByTagName("html")[0]);
			sendResponse({JSONDOM: mem0r1es.injectable.JSONDOM});
		}
	}
);