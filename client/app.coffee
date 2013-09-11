config = require('../config/app.json')

localStorage = require('localStorage')
Map = require('./map.coffee')
Terrain = require('./terrain')
TerrainStreamer = require('./terrain/streamer.coffee')

$ = require('jquery')

$ ->

  $('#locations').on('change', (e) ->
    location.hash = $('#locations option:selected').val()
    location.reload()
  )
  if location.hash
    $('#locations option[value="'+location.hash+'"]').attr('selected', 'selected')

  # Restore map from either location hash or localstorage
  rectangle = null
  zoom = 15
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
    location.hash = "#67.31285290844802%2C14.441993143622962%2C67.25053169095976%2C14.2774269944074"
    location.reload()

  map = new Map(config.tilesUrl, {
      attribution: "N50 UTM33 (Bengler)",
      zoom: zoom,
      rectangleEditor: rectangle_editor
    }
  )

  syncTerrainWithSelector = ->
    terrain.show(
      map.crs.project(rectangle_editor.getMarkerBounds()[0].getNorthWest()),
      map.crs.project(rectangle_editor.getMarkerBounds()[0].getSouthEast())
    )


  map.on 'change', (event) ->
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
