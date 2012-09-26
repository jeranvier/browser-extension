var mem0r1es=mem0r1es || {};

mem0r1es.navigationListener = function(){
	var self = this;
	
	this.getDOMCallback = function(response){
			console.log(response.JSONDOM);
		}
	
	
	this.onCompletedCallback = function(details){
		console.log("("+details.tabId+") "+details.url);
		mem0r1es.sendMessage(details.tabId, {query:"getJSONDOM"}, self.getDOMCallback);
	}
	
	chrome.webNavigation.onCompleted.addListener(this.onCompletedCallback,{urls: ["*://*/*"]},[]);
}