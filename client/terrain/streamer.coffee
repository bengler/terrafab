L = require("leaflet")


min = (a,b) ->
  if a<b then a else b

max = (a,b) ->
  if a>b then a else b


# Returns a new bounds where the bounds have been clipped to the provided clip boundaries
L.Bounds.prototype.clipTo = (clip) ->
  return null unless @intersects(clip)
  new L.Bounds([
    [max(@min.x, clip.min.x), max(@min.y, clip.min.y)]
    [min(clip.max.x, @max.x), min(clip.max.y, @max.y)]
  ])

meterSelectionToPixelBounds = (selection, bounds, pixelsPerMeter, scale) ->
  new L.Bounds([
    [
      (selection.min.x-bounds.min.x)*pixelsPerMeter*scale,
      (selection.min.y-bounds.min.y)*pixelsPerMeter*scale
    ], [
      (selection.max.x-bounds.min.x)*pixelsPerMeter*scale,
      (selection.max.y-bounds.min.y)*pixelsPerMeter*scale
    ]
  ])

# How many times higher resolutions should the maps have in relation to the terrain pxWidth
MAP_SCALE = 2

# How many tiles should we keep in the cache
TILE_CACHE_LIMIT = 40

class TerrainTile
  constructor: (@bounds, @pxWidth) ->
    @pxHeight = Math.round(@pxWidth/@meterWidth()*@meterHeight())
    @resolution = @pxWidth/@meterWidth()
    @terrainImage = new Image()
    @terrainImage.src = "/dtm?box=#{[@bounds.min.x, @bounds.max.y, @bounds.max.x, @bounds.min.y].join(',')}&outsize=#{@pxWidth},#{@pxHeight}"
    @mapImage = new Image()
    @mapImage.src = "/map?box=#{[@bounds.min.x, @bounds.max.y, @bounds.max.x, @bounds.min.y].join(',')}&outsize=#{@pxWidth*MAP_SCALE},#{@pxHeight*MAP_SCALE}"
  meterHeight: ->
    Math.abs(@bounds.max.y-@bounds.min.y)
  meterWidth: ->
    Math.abs(@bounds.max.x-@bounds.min.x)
  isLoaded: ->
    (@terrain.width > 0) && (@map.width > 0)
  # Converts the provided bounds in UTM33 meters to the same rectangle in tile-local pixel coordinates at the given scale
  meterSelectionToTerrainPixelBounds: (selection) ->
    meterSelectionToPixelBounds(selection, @bounds, @resolution, 1.0)
  meterSelectionToMapPixelBounds: (selection) ->
    meterSelectionToPixelBounds(selection, @bounds, @resolution, MAP_SCALE)

class TerrainStreamer
  constructor: (@pxWidth) ->
    @terrain = document.createElement("canvas")
    @terrain.width =  @pxWidth
    @terrain.height = @pxWidth
    @terrainCtx = @terrain.getContext('2d')
    @map = document.createElement("canvas")
    @map.width = @pxWidth*MAP_SCALE
    @map.height = @pxWidth*MAP_SCALE
    @mapCtx = @map.getContext('2d')
    @tiles = []
    @bounds = null
  load: (bounds, width) ->
    console.log "load", arguments
    @tiles.push(new TerrainTile(bounds, width))
    @purgeCache()
  purgeCache: ->
    # A naïve purging strategy for now. Just throw away the older tiles
    while @tiles.length > TILE_CACHE_LIMIT
      @tiles.shift()
  relevantTiles: ->
    result = []
    return result unless @bounds?
    # Select tiles that intersect the provided bounds
    for tile in @tiles
      result.push(tile) if tile.bounds.intersects(@bounds)
    # Sort tiles from lower to higher resolution
    result.sort (a, b) ->
      a.resolution - b.resolution
    result
  drawTile: (tile) ->
    return unless @bounds?
    # Determine what area of the tile overlaps the current target bounds
    segment = tile.bounds.clipTo(@bounds)
    # Map the segment to pixel coordinates of the source terrain bitmap
    sourceRect = tile.meterSelectionToTerrainPixelBounds(segment)
    terrainResolution = @pxWidth/@bounds.getSize().x
    # Map the segment to the pixel coordinates of the target terrain bitmap
    targetRect = meterSelectionToPixelBounds(segment, @bounds, terrainResolution, 1.0)
    # The effective resolution is the source pixels to target pixels ratio. Anything >= 1.0 means full resolution,
    # a lower value means the bitmap has been stretched to fit.
    effectiveResolution = sourceRect.getSize().x/targetRect.getSize().x
    # Only draw if the terrain has been loaded
    if tile.terrainImage.width > 0
      @terrainCtx.drawImage(tile.terrainImage,
        sourceRect.min.x, (tile.pxHeight-sourceRect.max.y), sourceRect.getSize().x, sourceRect.getSize().y,
        targetRect.min.x, targetRect.min.y, targetRect.getSize().x, targetRect.getSize().y)
    # Only draw if the map has been loaded
    if tile.mapImage.width > 0
      @mapCtx.drawImage(tile.mapImage,
        sourceRect.min.x*MAP_SCALE, (tile.pxHeight-sourceRect.max.y)*MAP_SCALE, sourceRect.getSize().x*MAP_SCALE, sourceRect.getSize().y*MAP_SCALE,
        targetRect.min.x*MAP_SCALE, targetRect.min.y*MAP_SCALE, targetRect.getSize().x*MAP_SCALE, targetRect.getSize().y*MAP_SCALE)
    # We will return the effective resolution even if the tile was not actually loaded yet. Even if that resolution is only incoming
    # we will consider it present in the system.
    effectiveResolution
  loadExtended: (areaFactor, scaleFactor) ->
    areaFactor -= 2.0
    size = @bounds.getSize()
    newBounds =
      new L.Bounds([
          [@bounds.min.x-size.x*areaFactor, @bounds.min.y-size.y*areaFactor],
          [@bounds.max.x+size.x*areaFactor, @bounds.max.y+size.y*areaFactor]
        ])
    # Load the area with 30% extra pixels to allow for some resizing too
    @load(newBounds, Math.floor(@pxWidth*3*scaleFactor))

  update: (bounds) ->
    @terrainCtx.clearRect(0,0,@pxWidth,@pxWidth)
    @mapCtx.clearRect(0,0,@pxWidth*MAP_SCALE,@pxWidth*MAP_SCALE)
    @bounds = bounds if bounds?
    resolution = 0
    for tile in @relevantTiles()
      effectiveResolution = @drawTile(tile)
      # We keep track of the effective resolution of the highest resolution tile that covers the whole area
      if tile.bounds.contains(@bounds)
        resolution = effectiveResolution
        break if resolution >= 1.0
    # If there is no data at all, we need to load a new atlas area
    unless resolution >= 0.05
      @loadExtended(30.0, 1.3)
    # If the effective resolution is anything less than full, we will order some more data from the server allowing for
    # some scrolling and resizing
    unless resolution >= 1.0
      @loadExtended(3.0, 1.3)

module.exports = TerrainStreamer
