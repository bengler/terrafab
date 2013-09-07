THREE = require "three"
TerrainBuilder = require('./builder.coffee')

THREE.Object3D.prototype.constructor = THREE.Object3D
class TerrainObject extends THREE.Object3D
  constructor: (lat, lon, radius) ->
    super
    @builder = new TerrainBuilder(75, 75, 3, 0.1)
    @builder.applyElevation()
    @textureCanvas = document.createElement("canvas")
    @textureCanvas.width = 1024
    @textureCanvas.height = 1024
    ctx = @textureCanvas.getContext('2d')
    ctx.fillStyle = '#dddddd'
    ctx.fillRect(0,0,1024,1024)
    @textureMaterial =  new THREE.MeshLambertMaterial
        map: new THREE.Texture(@textureCanvas)
        color: 0xdddddd
        ambient: 0xdddddd
        shading: THREE.SmoothShading
    @material = new THREE.MeshFaceMaterial([
      @textureMaterial
      new THREE.MeshLambertMaterial
        color: 0xffdddd
        shading: THREE.FlatShading
    ])
    #@material = new THREE.MeshBasicMaterial( { color: 0xff0000, wireframe: true } )
    @mesh = new THREE.Mesh(@builder.geom, @material)
    @add(@mesh)
    image = new Image()
    image.src = "/maps/api/staticmap?center=68.293272,14.794901&zoom=12&size=1024x1024&sensor=false"
    image.onload = =>
      @textureCanvas.getContext('2d').drawImage(image,0,0, 1024, 1024)
      @textureMaterial.map.needsUpdate = true
      console.log "Texture loaded"

module.exports = TerrainObject
