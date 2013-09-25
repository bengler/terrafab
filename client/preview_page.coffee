# Scripts for the model preview page

$ = require("jquery")
Terrain = require('./terrain')
TerrainStreamer = require('./terrain/streamer.coffee')
L = require("leaflet")

BoxParams = require("./utils/boxparam.coffee")

$ ->
  canvas = $('canvas#terrain')[0]
  terrain = new Terrain(canvas)
  terrain.scene.continousRotation = true
  terrain.run()
  {ne, sw} = BoxParams.fromUrl(document.location)
  terrain.show(ne, sw)

# Yeah, the progress report is just smoke and mirrors.
$('.progress p').hide()
$('.progress').show()
item = 0
length = $('.progress p').length
$( $('.progress p')[item] ).show()
progress = ->
  $('.progress p').hide()
  if(item<length)
    $( $('.progress p')[item] ).show()
    item++;
    if( item == length)
      $('.progress').remove()
      $('.downloadButton').removeClass('disabled').attr("href", "/download"+window.location.search)
      f = ->
        $('.buyButton').removeClass('disabled')
      setTimeout(f, 600)
      f = -> $('.readyHeader').html("Your model is ready")
      setTimeout(f, 300)
      clearInterval(interval)

interval = setInterval(progress, 1200)
