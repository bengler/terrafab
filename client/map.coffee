leaflet = require("leaflet")

require("./rectangle_editor")
require("./ext_js/proj4js-compressed.js")
require("./ext_js/proj4leaflet.js")

EventEmitter = require("events").EventEmitter

class Map extends EventEmitter

  constructor: (@tilesUrl, @options={}) ->
    @attribution = options.attribution || "UTM 33 / EPSG:32633"
    @resolutions = @options.resolutions || [
      5545984, 2772992, 1386496, 693248,
      346624, 173312, 86656, 43328,
      21664, 10832, 5416, 2708,
      1354, 677, 338.5,
      169.25, 84.625, 42.3125, 21.15625,
      10.578125, 5.2890625, 1
    ]
    @crs = new L.Proj.CRS('EPSG:32633',
        '+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs',
          {resolutions: @resolutions})
    @zoom = @options.zoom || 15
    @rectangleEditor = options.rectangleEditor || new L.RectangleEditor()
    @_registerCallbacks()
    @map = new L.Map('map', {
      crs: @crs,
      scale: (zoom) ->
          return 1 / @resolutions[zoom]
      ,
      layers: [
        new L.TileLayer(@tilesUrl, {
          attribution: @attribution,
          minZoom: 1,
          maxZoom: @resolutions.length-1,
          continuousWorld: true,
          worldCopyJump: false,
          noWrap: true
        })
      ].concat(options.layers || []),
      center: @options.center || [67.098449,15.449095],
      zoom: @zoom
    })
    @rectangleEditor.addTo(@map)
    setTimeout((=> @map.fitBounds(@rectangleEditor.getMarkerBounds())), 1)
    @
  _registerCallbacks: ->
    @rectangleEditor.on('change', (e) =>
      @emit('change', e)
    )
  project: (projection) ->
    @map.removeLayer(@rectangleEditor)
    @rectangleEditor = new L.RectangleEditor(projection.rectangle)
    @_registerCallbacks()
    @rectangleEditor.addTo(@map)
    setTimeout(=>
      @map.fitBounds(@rectangleEditor.getBounds())
    , 1000)
    setTimeout(=>
      @map.setZoom(projection.zoom || @zoom)
    , 1000)


  getZoom: ->
    return @map.getZoom()

module.exports = Map
