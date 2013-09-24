$ = window.$ = require("jquery")

config = require('../config/app.json')
Map = require('./map.coffee')
localStorage = require('localStorage')
Terrain = require('./terrain')
TerrainStreamer = require('./terrain/streamer.coffee')
SuggestionCompleter = require('./suggestion_completer.coffee')
require('./preview_page.coffee')


$ ->
  $('.waitForLoad').show();
  if window.location.pathname == "/"
    # Set up place search autocompleter
    suggestionCompleter = new SuggestionCompleter($("#q"), $("#autocomplete"),
        {host: config.elasticSearch.server.host}
    )
    suggestionCompleter.on('submit', (completion) ->
      map.setPosition(new L.LatLng(completion.payload.lat, completion.payload.lng))
    )

    hashToProjection = (hash) ->
      projection = {}
      uncoded = decodeURIComponent(hash)
      rectangle = uncoded.split('|')[0].substring(1,hash.length).split(',')
      projection.rectangle = [[rectangle[0],rectangle[1]],[rectangle[2], rectangle[3]]]
      projection.zoom = uncoded.split('|')[1]
      projection

    $('#locations').on('change', (e) ->
      location.hash = $('#locations option:selected').val()
      map.project(hashToProjection(location.hash))
      syncTerrainWithSelector()
      $('#locations option[value="'+location.hash+'"]').attr('selected', 'selected')
    )

    # Restore map from either location hash or localstorage
    if location.hash
      rectangle_editor = new L.RectangleEditor(
        hashToProjection(location.hash).rectangle
      )
      zoom = hashToProjection(location.hash).zoom
    else if localStorage and localStorage.getItem('rectangle')
      rectangle = JSON.parse(localStorage.getItem('rectangle'))
      rectangle_editor = new L.RectangleEditor(
        [
          [rectangle._southWest.lat, rectangle._southWest.lng],
          [rectangle._northEast.lat, rectangle._northEast.lng]
        ]
      )
      zoom = localStorage.getItem('zoom')
    else
      rectangle_editor = new L.RectangleEditor(
        [
          [67.31285290844802, 14.441993143622962]
          [67.25053169095976, 14.2774269944074]
        ]
      )
      zoom = 19

    map = new Map(config.tilesUrl, {
        attribution: config.leaflet.attribution,
        zoom: zoom,
        rectangleEditor: rectangle_editor
      }
    )

    syncTerrainWithSelector = ->
      terrain.show(
        map.crs.project(map.rectangleEditor.getMarkerBounds()[0].getNorthWest()),
        map.crs.project(map.rectangleEditor.getMarkerBounds()[0].getSouthEast())
      )
    syncSelection = ->
      syncTerrainWithSelector()
      $("#utm").val(""+map.rectangleEditor.getCenterLatLng()[1])
      $("#wgs84").val(""+map.rectangleEditor.getCenterLatLng()[0])

    $('#panic').on('click', (e) ->
      location.reload()
    )
    map.on 'change', (event) ->
      syncSelection()

    map.rectangleEditor.on 'mouseup', (event) ->
      location.hash = encodeURIComponent([
          [event.bounds._northEast.lat, event.bounds._northEast.lng],
          [event.bounds._southWest.lat, event.bounds._southWest.lng]
        ])+'|'+map.getZoom()
      if localStorage
        localStorage.setItem('rectangle', JSON.stringify(event.bounds))
        localStorage.setItem('zoom', map.getZoom())

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
