# The interface between the DOM and the Terrain-rendering stack.

THREE = require "three"
TerrainScene = require('./scene.coffee')

class TerrainComponent
  constructor: (@el) ->
    @renderer = new THREE.WebGLRenderer(canvas: @el)
    @renderer.setClearColor(0x0, 0.0)
    @resize()
    @scene = new TerrainScene()
  resize: ->
    @renderer.setSize(@el.width, @el.height)
  run: ->
    animate = =>
      requestAnimationFrame(animate)
      @scene.advance()
      @renderer.render(@scene, @scene.camera)
    animate()
  show: (nwPoint, sePoint) ->
    @scene.terrain.show(arguments...)

module.exports = TerrainComponent
