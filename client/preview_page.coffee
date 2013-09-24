# Scripts for the model preview page
if window.location.href.match("/preview")
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
	      clearInterval(interval)

	interval = setInterval(progress, 1500)
