$ = window.$ = require("jquery")
L = require("leaflet")
Terrain = require("./terrain")

require("./ext_js/proj4js-compressed.js")
require("./ext_js/proj4leaflet.js")
require("./rectangle_editor")

config = require('../config/app.json')

$ ->
  resolutions = [
    5545984, 2772992, 1386496, 693248,
    346624, 173312, 86656, 43328,
    21664, 10832, 5416, 2708,
    1354, 677, 338.5,
    169.25, 84.625, 42.3125, 21.15625,
    10.578125, 5.2890625, 1
  ]

  crs = new L.Proj.CRS('EPSG:32633', '+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs', {resolutions})

  map = new L.Map('map', {
    crs: crs,
    layers: [
      new L.TileLayer(config.tilesUrl, {
        attribution: config.attribution,
        minZoom: 1,
        maxZoom: resolutions.length - 1,
        continuousWorld: true,
        worldCopyJump: false,
        noWrap: true
      })
    ],
    center: [60.84751214857874,7.855133604041304],
    zoom: 15
    scale: (zoom) ->
      return 1 / resolutions[zoom]

  })

  rectangleEditor = new L.RectangleEditor([[60.84751214857874,7.855133604041304],[60.651121757063,7.765658244480659]])
  rectangleEditor.addTo(map)

  map.on 'click', (e)->
    rectangleEditor.setCenter(e.latlng)

  syncTerrainWithSelector = ->
    terrain.show(
      crs.project(rectangleEditor.getSouthWest()),
      crs.project(rectangleEditor.getNorthEast())
    )

  canvas = $('canvas#terrain')[0]
  terrain = new Terrain(canvas)
  terrain.run()
  syncTerrainWithSelector()
  $("#q").focus()
  $("#goToPreviewButton").click ->
    bounds = terrain.getBounds()
    unless bounds?
      console.log "Too soon."
      return
    window.location = "/preview?box=#{[bounds.min.x, bounds.min.y, bounds.max.x, bounds.max.y].join(',')}"

  syncSelection = ->
    syncTerrainWithSelector()
    center = rectangleEditor.getCenter()

  rectangleEditor.on 'change', (e)->
    syncSelection()
