class TerrainTile
  constructor: (@bounds, @pxWidth) ->
    @pxHeight = Math.round(@pxWidth/@meterWidth()*@meterHeight())
    @resolution = @pxWidth()/@meterWidth()
    @terrain = new Image()
    @terrain.src = "/dtm?box=#{[@bounds.min.x, @bounds.min.y, @bounds.max.x, @bounds.max.y].join(',')}&outsize=#{@pxWidth},#{@pxHeight}"
    @map = new Image()
    @map.src = "/map?box=#{[@bounds.min.x, @bounds.min.y, @bounds.max.x, @bounds.max.y].join(',')}&outsize=#{@pxWidth},#{@pxHeight}"
  meterHeight: ->
    Math.abs(@bounds.max.y-@bounds.min.y)
  meterWidth: ->
    Math.abs(@bounds.max.x-@bounds.min.x)
  isLoaded: ->
    (@terrain.width > 0) && (@map.width > 0)

class TileManager
  constructor: ->
    @tiles = []
  load: 