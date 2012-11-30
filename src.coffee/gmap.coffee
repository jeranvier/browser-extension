window.mem0r1es = {} if not window.mem0r1es?

class window.mem0r1es.gmap

  constructor : () ->
    document.addEventListener 'DOMContentLoaded', () =>
      @createListeners()
    ,false

  initializeMap : (latitude, longitude) =>
    myLatlng = new google.maps.LatLng latitude, longitude
    mapOptions =
      zoom: 18
      center: myLatlng
      mapTypeId: google.maps.MapTypeId.ROADMAP
    @map = new google.maps.Map document.getElementById('map_canvas'), mapOptions
    @placeMarker myLatlng
      
    google.maps.event.addListener @map, 'click', (event) =>
      @placeMarker event.latLng
      return
      
  placeMarker : (location) ->
    if @marker?
      @marker.setMap null
      @marker = null
    
    @marker = new google.maps.Marker {position: location, map: @map}
  
  createListeners : () =>
    window.addEventListener 'message', (event) =>
      if event.data.title is "coordinates"
        @initializeMap event.data.content.latitude, event.data.content.longitude
        event.source.postMessage {hello:"hello"}, event.origin
      
      if event.data.title is "getExactCoordinates"
        event.source.postMessage {title:"latestCoordinates", content:{latitude: @marker.position.lat(), longitude: @marker.position.lng()}}, event.origin
        
      return
    
gmap = new mem0r1es.gmap()
