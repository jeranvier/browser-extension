var mem0r1es=mem0r1es || {};

mem0r1es.networkListener = function(){
	
	this.onBeforeRequestCallback = function(details){
		console.log(details.url);
	}
	
	chrome.webRequest.onCompleted.addListener(this.onBeforeRequestCallback,{urls: ["*://*/*"]},[]);
}



