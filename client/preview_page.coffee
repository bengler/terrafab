Terrain = require('./terrain')
TerrainStreamer = require('./terrain/streamer.coffee')
L = require("leaflet")

$ = window.jQuery = require('jquery')
require('./ext_js/jquery.fileDownload')

parseBoxParams = ->
	return /(?:box\=)([0-9\.\,]+)/.exec(window.location.search)[1].split(',')

# Scripts for the model preview page
if window.location.href.match("/preview")
	$ ->
    canvas = $('canvas#terrain')[0]
    terrain = new Terrain(canvas)
    terrain.scene.continousRotation = true
    terrain.run()
    box = parseBoxParams()
    terrain.show(new L.Point(box[0], box[1]), new L.Point(box[2], box[3]))

	# Yeah, the progress report is just smoke and mirrors.
	$('.progress p').hide()
	$('.progress').show()
	item = 0
	length = $('.progress p').length

	doDownload = (url) ->
		return if $('.downloadButton').hasClass('disabled')
		oldButtonContent = ""
		document.cookie = "fileDownload=false"
		download = $.fileDownload url,
			prepareCallback: ->
				oldButtonContent = $('.downloadButton').html()
				$('.downloadButton').addClass('disabled').html("<div class='spinner'></div> Please wait!")
				console.log "Preparing to download"
			successCallback: ->
				$('.downloadButton').removeClass('disabled').html(oldButtonContent)
			failCallback: ->
				$('.downloadButton').removeClass('disabled').html(oldButtonContent)

	$( $('.progress p')[item] ).show()
	progress = ->
	  $('.progress p').hide()
	  if(item<length)
	    $( $('.progress p')[item] ).show()
	    item++;
	    if( item == length)
	      $('.progress').remove()
      	$('.downloadButton').removeClass('disabled').click ->
      		doDownload("/download"+window.location.search)


      	#attr("href", "/download"+window.location.search)
	      f = ->
		      $('.buyButton').removeClass('disabled')
		      $('.buyButton').on('click', (e) ->
		      	url = ""+window.location+""
		      	window.location = url.replace("/preview", "/cart")
		      	false
		      )
	      setTimeout(f, 600)
	      f = -> $('.readyHeader').html("Your model is ready")
	      setTimeout(f, 300)
	      clearInterval(interval)

	interval = setInterval(progress, 1200)
