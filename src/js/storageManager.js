var mem0r1es = mem0r1es || {};

window.indexedDB = window.webkitIndexedDB;
window.IDBTransaction = window.webkitIDBTransaction;


mem0r1es.storageManager = function(){
	this.db = null;
	this.version=3;
	this._ready=false;
	
	this.openDB = function(){
		var request = indexedDB.open("mem0r1es");
		var self=this;
		request.onsuccess = function(event){
			self.db = event.target.result;
			self.checkVersion();
			self._ready=true;
		}
		request.onfailure = this.onerror;
	}	
	
	this.checkVersion = function(){
		var self=this;
		if (this.version != this.db.version) {
			var setVersionrequest = this.db.setVersion(this.version);
			setVersionrequest.onfailure = this.onerror;
			setVersionrequest.onsuccess = function(e) {
				console.log("creating data store");
				var store = self.db.createObjectStore("browsingHistory", { autoIncrement: true });
				e.target.transaction.oncomplete = function() {
					console.log("data store created");
				};
			};
		}
		else{
			console.log("data store ready");
		}
	}
	
	this.onerror = function(){
		console.log("ERROR");
	}
	
	/* Handles messages received from background.js
	 */
	this.onMessage = function(message, sendResponse){
		console.log("message: "+message.content);
		switch(message.content){
			case "clearDB":
				this.clearDatabase(sendResponse);
				break;
			default:
				console.log("Could not understand the command "+message.content);
		}
	}
	
	this.isReady = function(){
		return this._ready;
	}
	
	/*Clears every data from the database and send an ack to the popup
	 *Argument: the methode used to respond to the popup
	 */
	this.clearDatabase = function(sendResponse){
		if(!this.isReady()){
			sendResponse({message:{content:"Database not ready", level:"warning"}});
			return false;
		}
	
		var trans = this.db.transaction(["browsingHistory"], "readwrite");
		var store = trans.objectStore("browsingHistory");
		if (store) {
			var clearReq = store.clear();
			clearReq.onsuccess = function (ev) {
			console.log("database cleared");
			sendResponse({message:{content:"database cleared", level:"success"}});
			}
			clearReq.onerror = function (ev) {
			console.log("Error while clearing database");
			sendResponse({message:{content:"Error while clearing database", level:"warning"}});
			}
		}
	}
	
	/* Stores an object corresponding to a page browsing in the datastore
	*/
	this.storeHistory = function(value){
		var trans = this.db.transaction(["browsingHistory"], "readwrite");
		var store = trans.objectStore("browsingHistory");
		var request = store.put(value);
		request.onsuccess = function(event){
			console.log(value+" [STORED]");
		};
		request.onerror = this.onerror; 
	}
}