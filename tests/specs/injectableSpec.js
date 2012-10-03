describe("The expected behavior of the injected script", function() {
  var DOMtoJSON;

  beforeEach(function() {
    DOMtoJSON = mem0r1es.injectable.DOMtoJSON(document.getElementsByTagName("html")[0]);
  });

  it("get the right nodes", function() {
	//title of the testing page
    expect(DOMtoJSON.children[0].children[0].text).toEqual("Jasmine Spec Runner");
  });

  it("catch the right attributes", function() {
	//rel attribut of the second link element (head)
    expect(DOMtoJSON.children[0].children[2].attributes["rel"]).toEqual("stylesheet");
  });
});

