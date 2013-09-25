# Scripts for index page

$ = window.$ = require("jquery")
L = require("leaflet")
Terrain = require("./terrain")

require("./ext_js/proj4js-compressed.js")
require("./ext_js/proj4leaflet.js")
require("./utils/rectangle_editor")

config = require('../config/app.json')
debounce = require("lodash.debounce")

BoxParam = require("./utils/boxparam.coffee")
resolutions = [
  5545984, 2772992, 1386496, 693248,
  346624, 173312, 86656, 43328,
  21664, 10832, 5416, 2708,
  1354, 677, 338.5,
  169.25, 84.625, 42.3125, 21.15625,
  10.578125, 5.2890625, 1
]
crs = new L.Proj.CRS('EPSG:32633', '+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs', {resolutions})

# Get box selection in LatLngs from either url, localstorage or default
selection = do ->
  box = if BoxParam.matches(document.location)
    BoxParam.fromUrl(document.location)
  else if (stored = localStorage.getItem('box'))
    # Remove key if doesnt match current format
    localStorage.removeItem('box') unless BoxParam.matches(stored)
    BoxParam.decode(stored)
  else
    BoxParam.decode("119452.67793424107,6946998.94376004,132390.62431972811,6959935.105363927|15")

latLngs = [crs.projection.unproject(selection.sw), crs.projection.unproject(selection.ne)]
rectangleEditor = new L.RectangleEditor(latLngs, {projection: crs.projection})

$ ->
  $('.waitForLoad').show();
  $('#bubble').hide() if sessionStorage.getItem('seenBubble')
  $('body').on 'click', '.closeBubbleAction', ->
    $('#bubble').hide()
    sessionStorage.setItem('seenBubble', true)

$ ->
  # Setup map, events, etc
  map = new L.Map('map', {
    crs: crs,
    layers: [
      new L.TileLayer(config.tilesUrl, {
        attribution: config.leaflet.attribution,
        minZoom: 1,
        maxZoom: resolutions.length - 1,
        continuousWorld: true,
        worldCopyJump: false,
        noWrap: true
      })
    ],
    center: rectangleEditor.getCenter(),
    zoom: selection.zoom || 15
    scale: (zoom) ->
      return 1 / resolutions[zoom]
  })

  rectangleEditor.addTo(map)

  map.on 'click', (e)->
    rectangleEditor.setCenter(e.latlng)

  do ->
    delay = (args...)-> setTimeout.apply(window, args.reverse())
    
    # Canvas stuff
    canvas = $('canvas#terrain')[0]

    # Delay setup of terrain a little to make page a little more responsive initially
    delay 300, ->
      terrain = new Terrain(canvas)
      terrain.run()

      syncTerrainWithSelector = ->
        terrain.show(crs.project(rectangleEditor.getSouthWest()), crs.project(rectangleEditor.getNorthEast()))
    
      rectangleEditor.on 'change', syncTerrainWithSelector
      syncTerrainWithSelector()

  serializedSelection = ->
    sw = crs.project(rectangleEditor.getSouthWest())
    ne = crs.project(rectangleEditor.getNorthEast())
    BoxParam.encode({sw, ne, zoom: map.getZoom()})

  do ->

    writeBoxToUrl = debounce(->
      history.replaceState({}, null, "/?box=#{serializedSelection()}")
    , 200)

    storeBox = debounce(->
      localStorage.setItem('box', serializedSelection())
    , 200)

    # Update document location when selected rect changes
    rectangleEditor.on 'change', writeBoxToUrl
    rectangleEditor.on 'change', storeBox

    # Also when map zoom level change
    map.on 'zoomend', writeBoxToUrl
    map.on 'zoomend', storeBox

    # Navigate to preview
    $("#goToPreviewButton").on 'click', ->
      window.location = "/preview?box=#{serializedSelection()}"

  do ->
    # Setup predefined locations select box
    $select = $('#locations')
    $select.on 'change', ->
      {sw, ne, zoom} = BoxParam.decode($select.val())
      rectangleEditor.setNorthEast(crs.projection.unproject(ne))
      rectangleEditor.setSouthWest(crs.projection.unproject(sw))
      map.fitBounds(rectangleEditor.getBounds())

  do ->
    # Set up place search autocompleter
    SuggestionCompleter = require("./utils/suggestion_completer.coffee")
    suggestionCompleter = new SuggestionCompleter($("#q"), $("#autocomplete"), {host: config.elasticSearch.server.host})
    suggestionCompleter.on 'submit', (completion) ->
      latLng = new L.LatLng(completion.payload.lat, completion.payload.lng)
      rectangleEditor.setCenter(latLng)
      map.panTo(latLng)
