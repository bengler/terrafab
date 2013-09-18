# An object representing the Scene as required by Three.js. It sets the light and camera
# mainly.

THREE = require "three"
TerrainObject = require('./object.coffee')

THREE.Scene.prototype.constructor = THREE.Scene
class TerrainScene extends THREE.Scene
  constructor: ->
    super
    @camera = new THREE.PerspectiveCamera(35)
    @camera.position.y = 80
    @camera.position.z = -200
    @camera.lookAt(new THREE.Vector3(0,-90,0))

    @terrain = new TerrainObject()
    @terrain.position.y = -120
    @add(@terrain)

    @light = new THREE.PointLight(0xffffff, 0.6, 0)
    @light.position.set(-100, 1050, -550)
    @add(@light)

    @light = new THREE.PointLight(0xffffff, 0.8, 0)
    @light.position.set(400, 550, -450)
    @add(@light)
    @t = 0.0

  advance: (time) ->
    @t += time || 1.0
    # Spinning the terrain
    @terrain.rotation.y = Math.sin(@t/200)*Math.PI/20+Math.PI
    @terrain.rotation.x = Math.sin(@t/240)*Math.PI/30

    # Looks at the size of the geometry and zooms out if it gets too big
    @targetFov = 35+(@terrain.mesh.geometry.boundingSphere.radius-70.5)*0.4
    @camera.fov = (@camera.fov*10+@targetFov)/11

    @camera.updateProjectionMatrix()
    @traverse (object) ->
      if object.tick?
        object.tick()

module.exports = TerrainScene
