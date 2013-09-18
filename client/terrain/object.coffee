# This is the 3D object representing the terrain. It stitches together the TerrainBuilder,
# and TerrainStreamer and provides a renderable object to the 3D engine THREE.

THREE = require "three"
TerrainBuilder = require('./builder.coffee')
TerrainStreamer = require('./streamer.coffee')
$ = require('jquery')
L = require('leaflet')

# What does the maximum value of terrain data represent in meters when using 8 bit terrain data?
OUT_RANGE = 2469

# The number of samples per dimension of the terrain model
SAMPLES_PER_SIDE = 200
GEOMETRY_UNITS_WIDE = 100.0

THREE.Object3D.prototype.constructor = THREE.Object3D
class TerrainObject extends THREE.Object3D
  constructor: (lat, lon, radius) ->
    super
    # Builds the mesh
    @builder = new TerrainBuilder(SAMPLES_PER_SIDE, SAMPLES_PER_SIDE, GEOMETRY_UNITS_WIDE)
    @builder.applyElevation()
    # Streams terrain data
    @streamer = new TerrainStreamer SAMPLES_PER_SIDE, (=> @terrainUpdateHandler())
    # The material for the terrain texture
    @textureMaterial =  new THREE.MeshLambertMaterial
        map: new THREE.Texture(@streamer.map)
        color: 0xcccccc
        ambient: 0xcccccc
        shading: THREE.SmoothShading
        #wireframe: true
        # magFilter: THREE.LinearFilter
        # minFilter: THREE.LinearMipMapLinearFilter
    # The meta-material containing both the texture-material, and a
    # material for the sides.
    @material = new THREE.MeshFaceMaterial([
      @textureMaterial
      new THREE.MeshLambertMaterial
        color: 0x999999
        shading: THREE.FlatShading
        side: THREE.DoubleSide
    ])
    #@material = new THREE.MeshBasicMaterial(wireframe: true, color: 0xff0000)
    # The mesh for the terrain
    @mesh = new THREE.Mesh(@builder.geom, @material)
    @add(@mesh)

    # A material for square drop shadows
    shadowMaterial = new THREE.MeshLambertMaterial
      map: new THREE.ImageUtils.loadTexture("/images/dropshadow.png")
      shading: THREE.FlatShading
      transparent: true
      opacity: 0.4
    # A mesh to put the drop shadow on, below the landscape
    shadow = new THREE.Mesh(new THREE.PlaneGeometry(GEOMETRY_UNITS_WIDE*1.15, GEOMETRY_UNITS_WIDE*1.15, 1, 1), shadowMaterial)
    # Place it below
    shadow.position.y = -6*@builder.scale
    # Turn it on its side
    shadow.rotation.x = -Math.PI/2
    # Add to scene
    @add(shadow)


  # Called by the client when it wants to update which area is being watched.
  # Currently the area is forced to become square
  show: (nwPoint, sePoint) ->
    area = new L.Bounds(nwPoint, sePoint)
    center = area.getCenter()
    size = area.getSize()
    halfside = (size.x+size.y)/4
    @streamer.setBounds(new L.Bounds(
        [center.x-halfside, center.y-halfside],
        [center.x+halfside, center.y+halfside]
      ))

  terrainUpdateHandler: ->
    @textureMaterial.map.needsUpdate = true
    if @streamer.hasRawRez()
      @builder.applyElevation(@streamer.rawRez, zScale: @terrainZScale(32767, OUT_RANGE))
    else
      @builder.applyElevation(@streamer.terrain, zScale: @terrainZScale(255, OUT_RANGE))

  terrainZScale: (inRange, outRange) ->
    return 0.0 unless @streamer.bounds?
    # Multiplying one sample by this factor gives the value in meters
    metersPerIncrement = outRange/inRange
    # One quad of the terrain is this wide in meters right now
    metersPerTerrainSample = @streamer.bounds.getSize().x/SAMPLES_PER_SIDE
    # When multiplying one value this value gives the altitude in multiples of
    # one width of a quad.
    return metersPerIncrement/metersPerTerrainSample

module.exports = TerrainObject
