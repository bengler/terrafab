require('./three_hacks.coffee')
TerrainData = require('./data.coffee')
TerrainBuilder = require '../client/terrain/builder.coffee'
toSTL = require './to_stl'
toX3D = require './to_x3d'

SAMPLES_PER_SIDE = 400
IN_RANGE = 32767.0
OUT_RANGE = 2469.0

class TerrainMesh
  constructor: (@terrainData) ->

  terrainZScale: ->
    # Multiplying one sample by this factor gives the value in meters
    metersPerIncrement = OUT_RANGE/IN_RANGE
    # One quad of the terrain is this wide in meters right now
    metersPerTerrainSample = @terrainData.width()/SAMPLES_PER_SIDE
    # When multiplying one value this value gives the altitude in multiples of
    # one width of a quad.
    return metersPerIncrement/metersPerTerrainSample

  getGeometry: ->
    return @geometry if @geometry?
    builder = new TerrainBuilder(SAMPLES_PER_SIDE, SAMPLES_PER_SIDE, 1.0)
    console.log "Scale: ", @terrainZScale()
    builder.applyElevation(@terrainData, zScale: (@terrainZScale()))
    @geometry = builder.geom

  asSTL: ->
    toSTL(@getGeometry())

  asX3D: ->
    toX3D(@getGeometry(), "terrain")

module.exports = TerrainMesh
