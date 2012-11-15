window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.Icon
  @canvas
  
  #Create the icon of the extension using canvas (more flexible)
  constructor : (status = "active")->
    if status is "active"
      colors = ["#999999", "#000000"]
      
    if status is "incognito"
      colors = ["#DDDDDD", "#DDDDDD"]
    @canvas = document.createElement "canvas"
    context = @canvas.getContext("2d")
    context.clearRect(0, 0, 19, 19)
    context.font = "12px 'Courier New'"
    context.fillStyle = colors[0]
    context.fillText("011010101", 0, 10)
    context.fillText("011010101", -4, 19)
    context.fillStyle = colors[1]
    context.fillText("0", 0, 10)
    context.fillText("1", 10, 19)
    
    if status is "incognito"
      context.font = "25px 'Courier New'"
      context.fillStyle = "#000000"
      context.strokeText("!", 3, 18)
    

    imageData = context.getImageData(0, 0, 19, 19)
    chrome.browserAction.setIcon {imageData: imageData}
    chrome.browserAction.setTitle {title: "Mem0r1es"}