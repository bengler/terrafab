# Common js to be run on all pages
$ = require("jquery")
  
$ ->
  $('.waitForLoad').show();
  $('#bubble').hide() if sessionStorage.getItem('seenBubble')
  $('body').on 'click', '.closeBubbleAction', ->
    $('#bubble').hide()
    sessionStorage.setItem('seenBubble', true)

