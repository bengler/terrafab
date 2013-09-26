# The interface between the DOM and the Terrain-rendering stack.

THREE = require "three"
TerrainScene = require('./scene.coffee')
require("../ext_js/three_effects")

class TerrainComponent
  constructor: (@el, opts={}) ->
    @scene = new TerrainScene(opts)
    @renderer = new THREE.WebGLRenderer(canvas: @el, antialias: true)
    @renderer.setClearColor(0x0, 0.0)
    @composer = new THREE.EffectComposer(@renderer)
    @composer.addPass(new THREE.RenderPass(@scene, @scene.camera, false, 0x0, 0.0))
    @hblur = new THREE.ShaderPass( THREE.HorizontalTiltShiftShader );
    @vblur = new THREE.ShaderPass( THREE.VerticalTiltShiftShader );
    bluriness = 3;
    @hblur.uniforms[ 'h' ].value = bluriness / @el.width;
    @vblur.uniforms[ 'v' ].value = bluriness / @el.height;
    @hblur.uniforms[ 'r' ].value = @vblur.uniforms[ 'r' ].value = 0.4;
    @vblur.renderToScreen = true
    @composer.addPass( @hblur );
    @composer.addPass( @vblur );

    @resize()
  resize: ->
    @renderer.setSize(@el.width, @el.height)
  run: ->
    animate = =>
      requestAnimationFrame(animate)
      @scene.advance()
      #@composer.render()
      @renderer.render(@scene, @scene.camera)
    animate()
  show: (nwPoint, sePoint) ->
    @scene.terrain.show(arguments...)
  getBounds: ->
    @scene.terrain.streamer.bounds

module.exports = TerrainComponent
