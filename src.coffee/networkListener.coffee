window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.NetworkListener

  constructor : (DocumentPreprocessorPool)->
    @DocumentPreprocessorPool = DocumentPreprocessorPool
    chrome.webRequest.onBeforeSendHeaders.addListener @onBeforeNavigate, {"urls":["*://*/*"]}, ["requestHeaders"]
    
  onBeforeNavigate : (details) =>
    refererFound = false
    if details.type is "main_frame"
      try
        for i in [0..details.requestHeaders.length]
          if details.requestHeaders[i].name is 'Referer'
            @DocumentPreprocessorPool.addRefererEntry details.url, details.requestHeaders[i].value
            refererFound = true
            break
      catch error
        @DocumentPreprocessorPool.addRefererEntry details.url, "noReferer"
      if not refererFound
        @DocumentPreprocessorPool.addRefererEntry details.url, "unknown"