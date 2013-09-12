config = require('../config/app.json')

localStorage = require('localStorage')
Map = require('./map.coffee')
Terrain = require('./terrain')
TerrainStreamer = require('./terrain/streamer.coffee')

$ = require('jquery')

$ ->

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
    rectangle_editor = new L.RectangleEditor(hashToProjection(location.hash).rectangle)
    zoom = hashToProjection(location.hash).zoom
  else if localStorage and localStorage.getItem('rectangle')
    rectangle = JSON.parse(localStorage.getItem('rectangle'))
    rectangle_editor = new L.RectangleEditor([[rectangle._southWest.lat, rectangle._southWest.lng],[rectangle._northEast.lat, rectangle._northEast.lng]])
    zoom = localStorage.getItem('zoom')

  map = new Map(config.tilesUrl, {
      attribution: "N50 UTM33 (Bengler)",
      zoom: zoom,
      rectangleEditor: rectangle_editor
    }
  )

  syncTerrainWithSelector = ->
    terrain.show(
      map.crs.project(map.rectangleEditor.getMarkerBounds()[0].getNorthWest()),
      map.crs.project(map.rectangleEditor.getMarkerBounds()[0].getSouthEast())
    )
    map.rectangleEditor.on 'dragend', (event) ->
      location.hash = encodeURIComponent([
          [event.bounds._northEast.lat, event.bounds._northEast.lng],
          [event.bounds._southWest.lat, event.bounds._southWest.lng]
        ])+'|'+map.getZoom()

  map.on 'change', (event) ->
    syncTerrainWithSelector()
    if localStorage
      localStorage.setItem('rectangle', JSON.stringify(event.bounds))
      localStorage.setItem('zoom', map.getZoom())

  canvas = $('canvas#terrain')[0]
  if false && canvas?
    ctx = canvas.getContext('2d')
    ctx.moveTo(0,0)
    ctx.lineTo(800,800)
    ctx.stroke()

  terrain = new Terrain(canvas)
  terrain.run()
  syncTerrainWithSelector()
