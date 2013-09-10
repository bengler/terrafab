THREE = require "three"
TerrainBuilder = require('./builder.coffee')
TerrainStreamer = require('./streamer.coffee')
$ = require('jquery')
L = require('leaflet')

THREE.Object3D.prototype.constructor = THREE.Object3D
class TerrainObject extends THREE.Object3D
  constructor: (lat, lon, radius) ->
    super
    @builder = new TerrainBuilder(200, 200, 1, 0.0008)
    @builder.applyElevation()
    @streamer = new TerrainStreamer(200)
    @textureCanvas = document.createElement("canvas")
    @textureCanvas.width = 400
    @textureCanvas.height = 400
    ctx = @textureCanvas.getContext('2d')
    ctx.fillStyle = '#dddddd'
    ctx.fillRect(0,0,1024,1024)
    @textureMaterial =  new THREE.MeshLambertMaterial
        map: new THREE.Texture(@textureCanvas)
        color: 0xcccccc
        ambient: 0xcccccc
        shading: THREE.SmoothShading
    @material = new THREE.MeshFaceMaterial([
      @textureMaterial
      new THREE.MeshLambertMaterial
        color: 0xffdddd
        shading: THREE.FlatShading
    ])
    #@textureMaterial.map.wrapS = THREE.RepeatWrapping;
    #@textureMaterial.map.wrapT = THREE.RepeatWrapping;

    #@material = new THREE.MeshBasicMaterial( { color: 0xff0000, wireframe: true } )
    @mesh = new THREE.Mesh(@builder.geom, @material)
    @add(@mesh)
    # @mapImage = new Image()
    # @mapImage.src = "/map?box=253723.176600653,6660500.4670516,267723.176600653,6646500.4670516&outsize=2000,2000"
    # @terrainImage = new Image()
    # @terrainImage.src = "/dtm?box=253723.176600653,6660500.4670516,267723.176600653,6646500.4670516&outsize=2000,2000"
    # @t = 0.0

  show: (nwPoint, sePoint) ->
    @streamer.update(new L.Bounds(nwPoint, sePoint))

  tick: ->
    @streamer.update()
    @builder.ctx.drawImage(@streamer.terrain, 0, 0)
    @builder.applyElevation()
    @textureCanvas.getContext('2d').drawImage(@streamer.map, 0, 0)
    @textureMaterial.map.needsUpdate = true

  _tick: ->
    @t += 0.4
    x = Math.sin(@t/200)
    y = Math.cos(@t/130)
    if @terrainImage.width > 0
      @builder.clear()
      ctx = @builder.ctx
      ctx.drawImage(@terrainImage, x*300-500, y*300-500)
      @builder.applyElevation()
    if @mapImage.width > 0
      ctx = @textureCanvas.getContext('2d')
      ctx.drawImage(@mapImage, x*300-500, y*300-500)
      @textureMaterial.map.needsUpdate = true

module.exports = TerrainObject
