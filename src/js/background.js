var mem0r1es=mem0r1es || {};

mem0r1es.init = function(){
	/* open and initialize the database
	 */
	mem0r1es.SM = new mem0r1es.storageManager();
	mem0r1es.SM.openDB();
	
	/* Create the icon for the popup
	 */
	mem0r1es.IC = new mem0r1es.icon();
	
	/*Initialize the navigation listener
	 */
	 mem0r1es.NL = new mem0r1es.navigationListener();
	 
	 
	 
	/*Listen to messages from the popup (GUI) and redirect these messages to the right module, along with the method to send the response
	 */
	chrome.extension.onMessage.addListener(
		function(request, sender, sendResponse) {
			console.log("redirecting a message to "+ request.module);
			switch(request.module){
				case "storageManager":
					mem0r1es.SM.onMessage(request.message, sendResponse);
					break;
				default:
					console.log("Could not redirect the message from the popup user interface. " + request.module + " is not a valid module");
			}
			return true; // the listener must return true if the response needs to be sent asynchronously
	});
	
	/*Send a message to a tab
	 */
	mem0r1es.sendMessage = function(tabId, message, callback){
		chrome.tabs.sendMessage(tabId, message, function(response){
			callback(response);
		});
	}
}

mem0r1es.init();





