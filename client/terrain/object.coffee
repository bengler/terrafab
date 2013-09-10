# This is the 3D object representing the terrain. It stitches together the TerrainBuilder,
# and TerrainStreamer and provides a renderable object to the 3D engine THREE.

THREE = require "three"
TerrainBuilder = require('./builder.coffee')
TerrainStreamer = require('./streamer.coffee')
$ = require('jquery')
L = require('leaflet')

# What does 255 represent in meters when using 8 bit terrain data?
RANGE_8BIT = 2404

# The number of samples per dimension of the terrain model
SAMPLES_PER_SIDE = 200


THREE.Object3D.prototype.constructor = THREE.Object3D
class TerrainObject extends THREE.Object3D
  constructor: (lat, lon, radius) ->
    super
    # Builds the mesh
    @builder = new TerrainBuilder(SAMPLES_PER_SIDE, SAMPLES_PER_SIDE, 1, 0.2)
    @builder.applyElevation()
    # Streams terrain data
    @streamer = new TerrainStreamer SAMPLES_PER_SIDE, =>
      @textureMaterial.map.needsUpdate = true
      @builder.applyElevation(@streamer.terrain, zScale: @currentTerrainZScale())
    # The material for the terrain texture
    @textureMaterial =  new THREE.MeshLambertMaterial
        map: new THREE.Texture(@streamer.map)
        color: 0xcccccc
        ambient: 0xcccccc
        shading: THREE.SmoothShading
    # The meta-material containing both the texture-material, and a
    # material for the sides.
    @material = new THREE.MeshFaceMaterial([
      @textureMaterial
      new THREE.MeshLambertMaterial
        color: 0xffdddd
        shading: THREE.FlatShading
    ])
    # The mesh for the terrain
    @mesh = new THREE.Mesh(@builder.geom, @material)
    @add(@mesh)

  # Called by the client when it wants to update which area is being watched.
  # Currently the area _must_ be a _square_ block of UTM33.
  show: (nwPoint, sePoint) ->
    @streamer.setBounds(new L.Bounds(nwPoint, sePoint))

  currentTerrainZScale: ->
    return 0.0 unless @streamer.bounds?
    # Multiplying one sample by this factor gives the value in meters
    metersPerIncrement = RANGE_8BIT/255
    # One quad of the terrain is this wide in meters right now
    metersPerTerrainSample = @streamer.bounds.getSize().x/SAMPLES_PER_SIDE
    # When multiplying one value this value gives the altitude in multiples of
    # one width of a quad.
    return metersPerIncrement/metersPerTerrainSample

module.exports = TerrainObject
