$ = window.$ = require("jquery")
L = require("leaflet")
Terrain = require("./terrain")

require("./ext_js/proj4js-compressed.js")
require("./ext_js/proj4leaflet.js")
require("./rectangle_editor")

RoutePattern = require("route-pattern")

config = require('../config/app.json')

$ ->
  $('.waitForLoad').show();

boxPattern = RoutePattern.fromString("?box=:box")

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

  #$('.closeBubbleAction').click ->
  $('#bubble').hide()

  if (match = boxPattern.match(document.location))
    box = match.queryParams.box.split(",")
    swPoint = L.point.apply(null, box.slice(0,2))
    nePoint = L.point.apply(null, box.slice(2))
    sw = crs.projection.unproject(swPoint)
    ne = crs.projection.unproject(nePoint)
    
    latLngs = [sw, ne]

  latLngs ||= [[60.84751214857874,7.855133604041304],[60.651121757063,7.765658244480659]]

  rectangleEditor = new L.RectangleEditor(latLngs, {projection: crs.projection})

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
    center: rectangleEditor.getCenter(),
    zoom: 15
    scale: (zoom) ->
      return 1 / resolutions[zoom]
  })

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

  $("#goToPreviewButton").click ->
    sw = crs.project(rectangleEditor.getSouthWest())
    ne = crs.project(rectangleEditor.getNorthEast())
    console.log(sw, ne)
    window.location = "/preview?box=#{[sw.x, sw.y, ne.x, ne.y].join(',')}"

  syncSelection = ->
    syncTerrainWithSelector()
    center = rectangleEditor.getCenter()

  rectangleEditor.on 'change', (e)->
    syncSelection()
