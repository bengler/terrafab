Terrain = require('./terrain')
TerrainStreamer = require('./terrain/streamer.coffee')
L = require("leaflet")

parseBoxParams = ->
	return /(?:box\=)([0-9\.\,]+)/.exec(window.location.search)[1].split(',')

# Scripts for the model preview page
if window.location.href.match("/preview")
	$ ->
    canvas = $('canvas#terrain')[0]
    terrain = new Terrain(canvas)
    terrain.run()
    box = parseBoxParams()
    terrain.show(new L.Point(box[0], box[1]), new L.Point(box[2], box[3]))

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
	      $('.downloadButton').removeClass('disabled')
	      $('.buyButton').removeClass('disabled')
	      $('.readyHeader').html("Your model is ready")
	      clearInterval(interval)

	interval = setInterval(progress, 700)
