THREE = require "three"
TerrainObject = require('./object.coffee')

terrainImage = new Image()
t = 0

THREE.Scene.prototype.constructor = THREE.Scene
class TerrainScene extends THREE.Scene
  constructor: ->
    super
    @camera = new THREE.PerspectiveCamera(45);
    @camera.position.y = 300
    @camera.position.z = -500
    @camera.lookAt(new THREE.Vector3(0,-100,0))

    # geometry = new THREE.CubeGeometry( 200, 200, 200 )
    # material = new THREE.MeshBasicMaterial( { color: 0xff0000, wireframe: true } )
    # mesh = new THREE.Mesh( geometry, material )
    # @add(mesh)

    @terrain = new TerrainObject()
    console.log @terrain
    @terrain.position.y = -120
    @add(@terrain)

    terrainImage.src = "/terrain?lat=68.293272&lon=14.794901&radius=6000"

    @mapImage = new Image()
    @mapImage.src = "/maps/api/staticmap?center=68.293272,14.794901&zoom=12&size=1024x1024&sensor=false"
    # image.onload = =>
    #   @textureCanvas.getContext('2d').drawImage(image,0,0, 1024, 1024)
    #   @material.map.needsUpdate = true
    #   console.log "Texture loaded"


    #terrainImage.src = "http://localhost:3000/terrain?lat=61.636667&lon=8.315&radius=5000"
    @light = new THREE.PointLight(0xffffff, 0.6, 0)
    @light.position.set(-100, 1050, -550)
    @add(@light)

    @light = new THREE.PointLight(0xffffff, 0.8, 0)
    @light.position.set(-2000, 2050, -150)
    @add(@light)

  advance: (time) ->
    t += 0.4
    @terrain.rotation.y += 0.005
    if terrainImage.width > 0
      @terrain.builder.clear()
      ctx = @terrain.builder.ctx
      x = Math.sin(t/200)
      y = Math.cos(t/130)
      ctx.drawImage(terrainImage, x*300-500, y*-500)
      @terrain.builder.applyElevation()

    @traverse (object) ->
      if object.tick?
        object.tick()

module.exports = TerrainScene
