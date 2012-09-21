var mem0r1es=mem0r1es || {};

mem0r1es.navigationListener = function(){
	
	this.onCompletedCallback = function(details){
		console.log(details.url);
	}
	
	chrome.webNavigation.onCompleted.addListener(this.onCompletedCallback,{urls: ["*://*/*"]},[]);
}



