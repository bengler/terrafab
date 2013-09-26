$ = require("jquery")

class LoadIndicator
  $win = $(window)

  constructor: (@$el, opts={@delay})->
    @delay ||= 0
    @_pending = []

  stop: ->
    @$el.fadeOut()
    @_timeout = clearTimeout(@_timeout)
  
  showAfter: (ms)->
    @_timeout = setTimeout((=> @show()), ms)
  
  show: ->
    @$el.fadeIn()
  
  queue: (jqXHR)->
    @showAfter(@delay) if @_pending.length == 0
    @_pending.push(jqXHR) if @_pending.indexOf(jqXHR) == -1
    jqXHR.always =>
      @_pending.splice(@_pending.indexOf(jqXHR), 1)
      @stop() if @_pending.length == 0
  
  module.exports = LoadIndicator 