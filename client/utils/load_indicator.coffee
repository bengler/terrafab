$ = require("jquery")

class LoadIndicator
  $win = $(window)

  constructor: (@$el, opts={@delay})->
    @delay ||= 0
    @_pending = []

  stop: ->
    @hide()
    @_timeout = clearTimeout(@_timeout)


  toggle: (showOrHide)->
    if (showOrHide) then @show() else @hide()
  
  showAfter: (ms)->
    @_timeout = setTimeout((=> @show()), ms)
  
  show: ->
    @$el.fadeIn()

  hide: ->
    @$el.fadeOut()

  queue: (jqXHR)->
    @showAfter(@delay) if @_pending.length == 0
    @_pending.push(jqXHR) if @_pending.indexOf(jqXHR) == -1
    jqXHR.always =>
      @_pending.splice(@_pending.indexOf(jqXHR), 1)
      @stop() if @_pending.length == 0
  
  module.exports = LoadIndicator 