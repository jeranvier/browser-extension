window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.Timeline

  constructor : (target, @timeSeries, @height=40 ,@width=500)->
    @barHeight = @height-25
    @chartMargin = 20
    @ticksRadius = 5
    @chart = d3.select(target).append("svg:svg").attr("width", @width).attr("height", @height).attr("id", "chart")
    @setMinAndMax()
    @setScale()
    @drawAxis()
    @drawBars()
    console.log "timeline created"
  
  setMinAndMax : () ->
    @min = @timeSeries[0].start
    @max = @timeSeries[@timeSeries.length-1].end
  
  setScale : () ->
    @xScale = d3.scale.linear().domain([@min, @max]).range([@chartMargin, @width-@chartMargin])
  
  drawAxis : () ->
    @chart.append("svg:line").attr("x1",@chartMargin).attr("y1", @height-15).attr("x2", @width-@chartMargin ).attr("y2", @height-15).attr("style","stroke:#2d578b;stroke-width:2")
    @drawTicks()
    return

  drawTicks : () =>
    ticks = @chart.selectAll("circles").data(@timeSeries).enter().append("svg:circle")
    .attr("cx", (datum) => return @xScale(datum.start))
    .attr("cy", @height-15)
    .attr("r", @ticksRadius)
    .attr("fill","#2d578b")
    
    @chart.selectAll("circles").data([@timeSeries[@timeSeries.length-1]]).enter().append("svg:circle").attr("cx", (datum) => return @xScale(datum.end)).attr("cy", @height-15).attr("r", @ticksRadius).attr("fill","#2d578b")
    ticks.on("mouseover", (d,i) =>
      ticks.filter((p) => return d is p ).transition().attr("r", @ticksRadius*1.5)
      @chart.selectAll("texts").data([d]).enter().append("svg:text").text((datum) =>
        date = new Date(datum.start)
        return "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"
      ).attr("x",d3.mouse(d3.event.target)[0]).attr("dx", -50).attr("y", @height).attr("id", "textOver").attr("font-family", "sans-serif").attr("font-size", 10).attr("fill", "#444499"))
      
      
    ticks.on("mouseout", (d,i) =>
      ticks.filter((p) => return d is p ).transition().attr("r", @ticksRadius)
      @chart.select("#textOver").remove())
      
     
    
    @chart.selectAll("texts").data([@timeSeries[0]]).enter().append("svg:text").text((datum) ->
      date = new Date(datum.start)
      return "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"
    ).attr("x",(datum) => return @xScale(datum.start)).attr("dx", -20).attr("y", @height).attr("font-family", "sans-serif").attr("font-size", 10).attr("fill", "#444499")
    
    @chart.selectAll("texts").data([@timeSeries[@timeSeries.length-1]]).enter().append("svg:text").text((datum) ->
      date = new Date(datum.end)
      return "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"
    ).attr("x",(datum) => return @xScale(datum.end)).attr("dx", -22).attr("y", @height).attr("font-family", "sans-serif").attr("font-size", 10).attr("fill", "#444499")
    
    
  drawBars : () ->
    @chart.selectAll("rect").data(@timeSeries).enter().append("svg:rect").attr("x", (datum) => return @xScale(datum.start)).attr("y", 0).attr("height", @barHeight ).attr("width", (datum) => return @xScale(datum.end)-@xScale(datum.start)-1).attr("fill", (datum) -> return if datum.value then return "#339933" else return "#CC0000")
   
  @processData = (data, attribute, end) ->
    processedData = []
    for i in [0..data.length-1]
      processedDatum = {}
      processedDatum.start = data[i].timestamp
      if data[i+1]?
        processedDatum.end = data[i+1].timestamp
      else
        processedDatum.end = end
      processedDatum.value = data[i][attribute]
      processedData.push processedDatum
    return processedData