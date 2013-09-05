#require("./webgl-example/blue-thing")

leaflet = require("leaflet")

require("./rectangle_editor")
require("./ext_js/proj4js-compressed.js")
require("./ext_js/proj4leaflet.js")

$ = require("jquery")

tilesUrl = 'http://skogsmaskin.asuscomm.com:3001/kartverk/{z}/{x}/{y}.png'
#tilesUrl = 'http://{s}.tile.osm.org/{z}/{x}/{y}.png'
tilesLayer = new L.TileLayer(tilesUrl);

$ ->

  resolutions = [5545984, 2772992, 1386496, 693248, 346624, 173312, 86656, 43328, 21664, 10832, 5416, 2708, 1354, 677, 338.5, 169.25, 84.625, 42.3125, 21.15625, 10.578125, 5.2890625, 1];
  map = new L.Map('map', {
    crs:  new L.Proj.CRS('EPSG:32633',
      '+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs',
      {
        resolutions: resolutions
      }
    ),
    scale: (zoom) ->
        return 1 / resolutions[zoom]
    ,
    layers: [
      new L.TileLayer(tilesUrl, {
        minZoom: 1,
        maxZoom: resolutions.length-1,
        continuousWorld: true,
        worldCopyJump: false
      })
    ],
    center: [59.918893,10.739715],
    zoom: 18
  });
  eRect = new L.RectangleEditor([[59.9,10.7],[59.928893,10.769715]],);
  map.addLayer(eRect);
