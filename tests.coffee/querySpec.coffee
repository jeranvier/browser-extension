describe "query specifications", ->
  it "should correctly chain", ->
    query = new mem0r1es.Query().from("temporary").where("a", "greaterThan", 2, false).and("b", "lowerThan", 2, true)
    expect(query.toString()).toBe "SELECT object FROM temporary WHERE a>=2 AND candidate.b<2"
    
  it "should correctly parse the keyRange", ->
    query1 = new mem0r1es.Query().from("temporary").where("a", "between", 1, false, 3, true)
    console.log query1
    expect(query1.keyRange.upper).toBe 3
    expect(query1.keyRange.lower).toBe 1
    expect(query1.keyRange.lowerOpen).toBeTruthy
    expect(query1.keyRange.upperOpen).not.tobeTruthy
    expect(query1.toString()).toBe "SELECT object FROM temporary WHERE 1<=a<3"