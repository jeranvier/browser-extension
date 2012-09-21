var mem0r1es=mem0r1es || {};

mem0r1es.popup = {};


/*create the event listeners for the buttons
*/
mem0r1es.popup.createListeners = function(){
	document.getElementById("clearDB").addEventListener('click', function(){mem0r1es.popup.sendMessage("storageManager", {content:"clearDB"}, mem0r1es.popup.clearDBCallback);}, false);
}

/* Send message from the popup (UI) to the extension.
 * Arguments: The module to which redirect the message, the message itself as a json and a callback to handle the response
 */
mem0r1es.popup.sendMessage = function(module,message, callback){
	chrome.extension.sendMessage({module:module, message:message}, function(response){
		if(callback != null){
			callback(response);
		}
	});
};

/*Callback triggered by the response from background.html related to a clearDB message
 */
mem0r1es.popup.clearDBCallback = function(response){
	mem0r1es.popup.displayMessage(response.message);
}

/*Once the page is loaded, set the event listeners
*/
document.addEventListener('DOMContentLoaded', function() {
	mem0r1es.popup.createListeners();
});

/* Displays a message in the notification area of the popup.
 * The message is a json with a content and a level (success, notice, warning, error)
 */
mem0r1es.popup.displayMessage = function(message){
	var node=document.createElement("DIV");
	node.setAttribute("class", "notification");
	node.setAttribute("id", message.level);
	var textnode=document.createTextNode(message.content);
	node.appendChild(textnode);
	document.getElementById("notifications").appendChild(node);
	
	setTimeout(function(){node.setAttribute("class", "notification hide");setTimeout(function(){document.getElementById("notifications").removeChild(node)},500);},3000);
}