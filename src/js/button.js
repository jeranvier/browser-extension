var mem0r1es=mem0r1es || {};

mem0r1es.icon = function(){
	
	/* Create the icon of the extension using canvas (more flexible)
	 */
	this.initIcon = function(){
		var canvas = document.createElement("canvas");
		var context = canvas.getContext('2d');
		context.clearRect ( 0 , 0 , 19 , 19 );
		context.font="12px 'Courier New'";
		context.fillStyle="#999999";
		context.fillText("011010101",0,10);
		context.fillText("011010101",-4,19);
		
		context.fillStyle="#000000";
		context.fillText("0",0,10);
		context.fillText("1",10,19);
		
		var imageData = context.getImageData(0, 0, 19, 19);
		chrome.browserAction.setIcon({imageData: imageData});
		chrome.browserAction.setTitle({title:"Mem0r1es"});
	}
	
	this.initIcon();
}







