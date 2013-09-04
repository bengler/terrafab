#require("./webgl-example/blue-thing")

leaflet = require("leaflet")
$ = require("jquery")

tilesUrl = 'http://skogsmaskin.asuscomm.com:3001/kartverk/{z}/{x}/{y}.png'
tilesLayer = new L.TileLayer(tilesUrl);

$ ->
  map = new L.Map('map');
  map.addLayer(tilesLayer);
  map.setView(new L.LatLng(59.918893,10.739715), 10);
