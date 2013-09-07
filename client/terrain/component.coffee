THREE = require "three"

TerrainScene = require('./scene.coffee')

class TerrainComponent
  constructor: (@el) ->
    @renderer = new THREE.WebGLRenderer(canvas: @el)
    @renderer.setClearColorHex(0x0, 0.0)
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

module.exports = TerrainComponent