// # of ms between each polling of a waitfor
var POLLING_INTERVAL = 10;

//custom waitsFor
var waitsFor = function (fct, callback){
  var res = fct();
  if (res){
    callback();
  }
  else{
    setTimeout(function(){waitsFor(fct, callback)},POLLING_INTERVAL);
  }
}

var beforeAll_ = null;
var beforeAll_done = false;
var afterAll_ = null;
var afterAll_done = false;

var beforeAll = function(fct){
  beforeAll_ = function(){fct();}
}

var afterAll = function(fct){
  afterAll_ = fct;
}

var runBeforeAll = function(){
  beforeAll_();
}