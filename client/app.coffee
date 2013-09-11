config = require("../config/app.json")

leaflet = require("leaflet")

localStorage = require('localStorage')

require("./rectangle_editor")
require("./ext_js/proj4js-compressed.js")
require("./ext_js/proj4leaflet.js")

Terrain = require('./terrain')
TerrainStreamer = require('./terrain/streamer.coffee')

$ = require("jquery")

$ ->

  resolutions = [
    5545984, 2772992, 1386496, 693248,
    346624, 173312, 86656, 43328,
    21664, 10832, 5416, 2708,
    1354, 677, 338.5,
    169.25, 84.625, 42.3125, 21.15625,
    10.578125, 5.2890625, 1
  ];

  crs = new L.Proj.CRS('EPSG:32633',
      '+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs',
      {
        resolutions: resolutions
      }
    )

  zoom = 15

  # Restore map from either hash or localstorage
  if location.hash
    rectangle = decodeURIComponent(location.hash).substring(1,location.hash.length).split(',')
    rectangle = [[rectangle[0],rectangle[1]],[rectangle[2], rectangle[3]]]
    rectangle_editor = new L.RectangleEditor(rectangle)
    zoom = localStorage.getItem('zoom') || zoom
  else if localStorage and localStorage.getItem('rectangle')
    rectangle = JSON.parse(localStorage.getItem('rectangle'))
    rectangle_editor = new L.RectangleEditor([[rectangle._southWest.lat, rectangle._southWest.lng],[rectangle._northEast.lat, rectangle._northEast.lng]])
    zoom = localStorage.getItem('zoom') || zoom
  else
    rectangle_editor = new L.RectangleEditor([[67.177414,15.212889],[67.035306,15.674314]])
  rectangle_editor.crs = crs;

  map = new L.Map('map', {
    crs: crs,
    scale: (zoom) ->
        return 1 / resolutions[zoom]
    ,
    layers: [
      new L.TileLayer(config.tilesUrl, {
        attribution: "N50 UTM33 (Bengler)",
        minZoom: 1,
        maxZoom: resolutions.length-1,
        continuousWorld: true,
        worldCopyJump: false,
        noWrap: true
      })
    ],
    center: [67.098449,15.449095],
    zoom: zoom
  });
  rectangle_editor.addTo(map)
  setTimeout((-> map.fitBounds(rectangle_editor.getMarkerBounds())), 1)

  syncTerrainWithSelector = ->
    terrain.show(
      crs.project(rectangle_editor.getMarkerBounds()[0].getNorthWest()),
      crs.project(rectangle_editor.getMarkerBounds()[0].getSouthEast())
    )

  rectangle_editor.on 'change', (event) ->
    syncTerrainWithSelector()
    if localStorage
      localStorage.setItem('rectangle', JSON.stringify(event.bounds))
      localStorage.setItem('zoom', map.getZoom())
    window.location.hash =  encodeURIComponent([
        [event.bounds._northEast.lat, event.bounds._northEast.lng],
        [event.bounds._southWest.lat, event.bounds._southWest.lng]
      ])

  canvas = $('canvas#terrain')[0]
  if false && canvas?
    ctx = canvas.getContext('2d')
    ctx.moveTo(0,0)
    ctx.lineTo(800,800)
    ctx.stroke()

  terrain = new Terrain(canvas)
  terrain.run()
  syncTerrainWithSelector()

