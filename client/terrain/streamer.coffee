# TerrainStreamer loads terrain and map data via a cache to provide real time feedback
# when manipulating the selected area.

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
  constructor: (@bounds, @pxWidth, onload = null) ->
    @pxHeight = Math.round(@pxWidth/@meterWidth()*@meterHeight())
    @resolution = @pxWidth/@meterWidth()
    @terrainImage = new Image()
    @terrainImage.onload = onload
    @terrainImage.src = "/dtm?box=#{[@bounds.min.x, @bounds.max.y, @bounds.max.x, @bounds.min.y].join(',')}&outsize=#{@pxWidth},#{@pxHeight}"
    @mapImage = new Image()
    @mapImage.onload = onload
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

class TerrainRawRez
  constructor: (@bounds, @pxWidth, onload = null) ->
    size = @bounds.getSize()
    @pxHeight = Math.round(@pxWidth/size.x*size.y)
    req = new XMLHttpRequest()
    req.responseType = 'arraybuffer'
    req.open('GET', "/dtm?box=#{[@bounds.min.x, @bounds.max.y, @bounds.max.x, @bounds.min.y].join(',')}&outsize=#{@pxWidth},#{@pxHeight}&format=bin", true)
    req.onload = (event) =>
      arrayBuffer = req.response
      window.ab = arrayBuffer
      if arrayBuffer
        @data = new Uint16Array(arrayBuffer)
      onload() if onload?
    req.send(null)
  isLoaded: ->
    @data?
  getSample: (x,y) ->
    @data[x+y*@pxWidth]

class TerrainStreamer
  # pxWidth is the amount of pixels along one side of the terrain image. The terrain will be square.
  # The map will be loaded in a higher resolution as dictated by the MAP_SCALE 'constant'.
  # Optionally a function may be provided that will be called whenever the output bitmaps are updated.
  constructor: (@pxWidth, @onupdate = null) ->
    @pxHeight = @pxWidth
    # The canvas where the terrain will be updated
    @terrain = document.createElement("canvas")
    @terrain.width =  @pxWidth
    @terrain.height = @pxWidth
    @terrainCtx = @terrain.getContext('2d')
    # The canvas where the corresponding map will be output
    @map = document.createElement("canvas")
    @map.width = @pxWidth*MAP_SCALE
    @map.height = @pxWidth*MAP_SCALE
    @mapCtx = @map.getContext('2d')
    # A cache of loaded tiles of terrain and map data
    @tiles = []
    # This variable will contain a Leaflet.Bounds-instance specifying the area the streamer should attempt
    # to represent.
    @bounds = null

  # Loads data for the provided bounds using a bitmap with 'width' pixels horizontally.
  load: (bounds, width) ->
    @tiles.push(new TerrainTile(bounds, width, (=> @update())))
    @purgeCache()

  # Purges the cache of old tiles
  purgeCache: ->
    # A naïve purging strategy for now. Just throw away the older tiles
    while @tiles.length > TILE_CACHE_LIMIT
      @tiles.shift()

  # Fetches the relevant tiles for the current @bounds area. Sorts them according to resolution from coarse
  # to fine.
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

  # Draws a given tile scaled and positioned correctly into the output canvases
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
        targetRect.min.x, (@pxHeight-targetRect.max.y), targetRect.getSize().x, targetRect.getSize().y)
    # Only draw if the map has been loaded
    if tile.mapImage.width > 0
      @mapCtx.drawImage(tile.mapImage,
        sourceRect.min.x*MAP_SCALE, (tile.pxHeight-sourceRect.max.y)*MAP_SCALE, sourceRect.getSize().x*MAP_SCALE, sourceRect.getSize().y*MAP_SCALE,
        targetRect.min.x*MAP_SCALE, (@pxHeight-targetRect.max.y)*MAP_SCALE, targetRect.getSize().x*MAP_SCALE, targetRect.getSize().y*MAP_SCALE)
    # We will return the effective resolution even if the tile was not actually loaded yet. Even if that resolution is only incoming
    # we will consider it present in the system.
    effectiveResolution

  # Loads a tile covering the current @bounds-area. An areaFactor of 1.0 loads exactly that area. An areaFactor of 3.0 will load
  # three times as much data around the area to allow for scrubbing. Similarly a scaleFactor of 1.0 loads the area in the exact
  # resolution required to display at current scale. A factor of 1.3 will allow the user to zoom 30% before needing to load more
  # data.
  loadExtended: (areaFactor, scaleFactor) ->
    f = (areaFactor-1.0)/2
    size = @bounds.getSize()
    newBounds =
      new L.Bounds([
          [@bounds.min.x-size.x*f, @bounds.min.y-size.y*f],
          [@bounds.max.x+size.x*f, @bounds.max.y+size.y*f]
        ])
    @load(newBounds, Math.floor(@pxWidth*scaleFactor*areaFactor))

  # "RawResolution" means the landscape in the current @bounds in full 16 bit resolution
  resetRawRez: ->
    @rawRez = null
    clearTimeout(@rawRezTimer)
    @rawRezTimer = setTimeout((=> @loadRawRez()), 1700)
  loadRawRez: ->
    @rawRez = new TerrainRawRez @bounds, @pxWidth, =>
      @onupdate() if @onupdate?
  hasRawRez: ->
    @rawRez? && @rawRez.isLoaded()

  # Call this to change what area the streamer is showing
  setBounds: (bounds) ->
    @bounds = bounds
    @resetRawRez()
    @update()

  # Called when new data arrive or bounds are updated to redraw map and terrain
  update: ->
    # Clear ouptut canvases
    @terrainCtx.clearRect(0,0,@pxWidth,@pxWidth)
    @mapCtx.fillStyle = "#aaa"
    @mapCtx.fillRect(0,0,@pxWidth*MAP_SCALE,@pxWidth*MAP_SCALE)
    @bounds = bounds if bounds?
    if @bounds?
      # This variable keeps track of the best resolution we had covering the entire output region
      resolution = 0
      for tile in @relevantTiles()
        effectiveResolution = @drawTile(tile)
        # We keep track of the effective resolution of the highest resolution tile that covers the whole area
        if tile.bounds.contains(@bounds)
          resolution = effectiveResolution
          break if resolution >= 1.0
      # If there is no coarse data to provide adequate preview, we need to load a new atlas area
      unless resolution >= 0.05
        @loadExtended(30.0, 0.3)
      # If the effective resolution is anything less than full, we will order some more data from the server allowing for
      # some scrolling and resizing
      unless resolution >= 1.0
        @loadExtended(3.0, 1.3)
    @onupdate() if @onupdate

module.exports = TerrainStreamer
