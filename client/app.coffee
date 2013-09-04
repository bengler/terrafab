#require("./webgl-example/blue-thing")

leaflet = require("leaflet")
require("./rectangle_editor")
$ = require("jquery")

tilesUrl = 'http://skogsmaskin.asuscomm.com:3001/kartverk/{z}/{x}/{y}.png'
tilesLayer = new L.TileLayer(tilesUrl);

$ ->
  map = new L.Map('map');
  map.addLayer(tilesLayer);
  map.setView(new L.LatLng(59.918893,10.739715), 10);

  do ->
    eRect = new L.RectangleEditor([[59.9,10.7],[59.928893,10.769715]],);
    map.addLayer(eRect);

    from = null
    to = null
    selectionRect = L.rectangle([[59.918893,10.739715], [59.918893,10.739715]], {color: "#ff7800", weight: 1, opacity: 0.5})
    added = false
    drawSelection = ()->
      selectionRect.setBounds([from, to])
      selectionRect.addTo(map) and added = true unless added
      console.log('draw', from, ' => ', to)

    setTo = (e)->
      console.log("omg")
      to = e.latlng
      drawSelection()
    
    endSelect = (e)->
      console.log('end select', e.latlng)
      map.once 'click', beginSelect
      map.off 'mouseover', setTo

    beginSelect = (e)->
      from = e.latlng
      to = e.latlng
      console.log('begin select from', from, 'to', to)
      map.once 'click', endSelect
      map.on 'mousemove', setTo

    map.once 'click', beginSelect
