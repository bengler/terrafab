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

  eRect = new L.RectangleEditor([[59.9,10.7],[59.928893,10.769715]],);
  map.addLayer(eRect);