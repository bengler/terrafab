# An object representing the Scene as required by Three.js. It sets the light and camera
# mainly.

THREE = require "three"
TerrainObject = require('./object.coffee')

THREE.Scene.prototype.constructor = THREE.Scene
class TerrainScene extends THREE.Scene
  constructor: ->
    super
    @camera = new THREE.PerspectiveCamera(35)
    @camera.position.y = 300
    @camera.position.z = -500
    @camera.lookAt(new THREE.Vector3(0,-100,0))

    @terrain = new TerrainObject()
    console.log @terrain
    @terrain.position.y = -120
    @add(@terrain)

    @mapImage = new Image()

    @light = new THREE.PointLight(0xffffff, 0.6, 0)
    @light.position.set(-100, 1050, -550)
    @add(@light)

    @light = new THREE.PointLight(0xffffff, 0.8, 0)
    @light.position.set(-2000, 2050, -150)
    @add(@light)

  advance: (time) ->
    @terrain.rotation.y += 0.005
    @traverse (object) ->
      if object.tick?
        object.tick()

module.exports = TerrainScene
