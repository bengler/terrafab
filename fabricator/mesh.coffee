require('./three_hacks.coffee')
TerrainData = require('./data.coffee')
TerrainBuilder = require '../client/terrain/builder.coffee'
toSTL = require './to_stl'
toX3D = require './to_x3d'
toSunflow = require './to_sunflow'

IN_RANGE = 32767.0
OUT_RANGE = 2469.0

class TerrainMesh
  constructor: (@terrainData, @carveUnderside = true) ->
  terrainZScale: ->
    # Multiplying one sample by this factor gives the value in meters
    metersPerIncrement = OUT_RANGE/IN_RANGE
    # One quad of the terrain is this wide in meters right now
    metersPerTerrainSample = @terrainData.width()/@terrainData.xsamples
    # When multiplying one value this value gives the altitude in multiples of
    # one width of a quad.
    return metersPerIncrement/metersPerTerrainSample

  build: ->
    @builder = new TerrainBuilder(@terrainData.xsamples, @terrainData.ysamples, 100.0)
    @builder.carveUnderside = @carveUnderside
    @builder.applyElevation(@terrainData, zScale: (@terrainZScale()))
    @geometry = @builder.geom
    @uvs = @builder.uvs
    @builder

  getBuilder: ->
    @builder = @build() unless @builder?
    @builder

  getGeometry: ->
    @build() unless @geometry?
    @geometry

  getUvs: ->
    @build() unless @uvs?
    @uvs

  asSTL: ->
    toSTL(@getGeometry())

  asX3D: ->
    toX3D(@getBuilder(), "terrain")

  asSC: ->
    toSunflow(@getBuilder())

module.exports = TerrainMesh
