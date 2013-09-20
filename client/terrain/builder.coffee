THREE = require "three"

class TerrainBuilder
  constructor: (@width, @height, unitsWide) ->
    @baseThickness = 5
    @scale = unitsWide/@width
    if document?
      @canvas ||= document.createElement("canvas")
      @canvas.width = @width
      @canvas.height = @height
      @ctx = @canvas.getContext('2d')
    @uvs = []
    @carveUnderside = false

  terrainCoordinateToVector: (x,y) ->
    new THREE.Vector3((x-@width/2)*@scale, 0, (y-@height/2)*@scale)
  terrainCoordinateToUV: (x,y) ->
    new THREE.Vector2(1.0*(x+0.5) / @width, 1.0-(1.0*(y+0.5) / @height))
  terrainCoordinateToVertexIndex: (x,y) ->
    x+y*@width

  # Bulds the top of the mesh. The patch of triangles that will be elevated to
  # display the terrain. Set isBottom to false in order to generate the bottom
  # of the terrain where faces are facing down
  buildTerrainMesh: (isBottom = false) ->
  # builds the default mesh without applying any elevation
    firstVertex = @geom.vertices.length
    # Add vertices for the terrain grid
    for y in [0...@height]
      for x in [0...@width]
        @geom.vertices.push(@terrainCoordinateToVector(x,y))
        # For each terrain vertex, also remember a corresponding UV coordinate for later
        @uvs.push(@terrainCoordinateToUV(x,y))
    # Add all the faces for the terrain grid
    for row in [0...(@width-1)]
      for column in [0...(@height-1)]
        # Corners of the current quad
        top_left = column+row*@width
        top_right = top_left+1
        bottom_left = top_left+@width
        bottom_right = top_right+@width
        unless isBottom
          # This is top terrain - faces will be facing up
          # Triangle one
          @geom.faces.push(new THREE.Face3(firstVertex+bottom_right, firstVertex+top_right, firstVertex+top_left))
          @geom.faceVertexUvs[0].push([@uvs[bottom_right], @uvs[top_right], @uvs[top_left]])
          # Triangle two
          @geom.faces.push(new THREE.Face3(firstVertex+bottom_left, firstVertex+bottom_right, firstVertex+top_left))
          @geom.faceVertexUvs[0].push([@uvs[bottom_left], @uvs[bottom_right], @uvs[top_left]])
        else
          # This is bottom terrain - faces will be facing down
          # Triangle one
          @geom.faces.push(new THREE.Face3(firstVertex+bottom_right, firstVertex+top_left, firstVertex+top_right))
          @geom.faceVertexUvs[0].push([@uvs[bottom_right], @uvs[top_left], @uvs[top_right]])
          # Triangle two
          @geom.faces.push(new THREE.Face3(firstVertex+bottom_right, firstVertex+bottom_left, firstVertex+top_left))
          @geom.faceVertexUvs[0].push([@uvs[bottom_right], @uvs[bottom_left], @uvs[top_left]])

  # The vertices below the terrain that will provide vertices for the sides of the terrain
  buildBaseVertices: ->
    # Generate the vertices of the bottom
    xMax = @width-1
    yMax = @height-1
    vertices = [
      @terrainCoordinateToVector(0,0)          # SW
      @terrainCoordinateToVector(xMax/2,0)     # S
      @terrainCoordinateToVector(xMax,0)       # SE
      @terrainCoordinateToVector(0,yMax/2)     # W
      @terrainCoordinateToVector(xMax,yMax/2)  # E
      @terrainCoordinateToVector(0, yMax)      # NW
      @terrainCoordinateToVector(xMax/2, yMax) # N
      @terrainCoordinateToVector(xMax, yMax)   # NE
    ]
    # Place all the base vertices a little bit below the water line
    vertex.y = -3*@scale for vertex in vertices
    # Remember the index of the first bottom vertex
    index = @geom.vertices.length
    # Append the vertices to the geometry
    @geom.vertices.push(vertices...)
    # Remember the index of each point in this convenient object
    @baseVertex =
      sw: index++
      s:  index++
      se: index++
      w:  index++
      e:  index++
      nw: index++
      n:  index++
      ne: index++
  # Builds one side given an index of a left, center and right bottom vertex index,
  # a count of terrain vertices and a function (indexOfTerrainVertex) producing terrain
  # vertex indicies along the desired edge.
  buildSide: (left, center, right, count, indexOfTerrainVertex) ->
    for n in [0...count-1]
      @geom.faces.push(new THREE.Face3(center, indexOfTerrainVertex(n), indexOfTerrainVertex(n+1)))
    @geom.faces.push(new THREE.Face3(center, left, indexOfTerrainVertex(0)))
    @geom.faces.push(new THREE.Face3(center, indexOfTerrainVertex(count-1), right))

  # Adds polygons to cap the bottom of the base
  buildBottomCap: ->
    for directions in [
        ['w', 'n', 'nw']
        ['n', 'e', 'ne']
        ['e', 's', 'se']
        ['s', 'w', 'sw']
        ['s', 'n', 'w']
        ['n', 's', 'e']]
      @geom.faces.push(new THREE.Face3(
        @baseVertex[directions[0]],
        @baseVertex[directions[1]],
        @baseVertex[directions[2]]))

  # Builds each side of the mesh coming across as a "base"
  buildBase: ->
    @buildBaseVertices()
    faceIndex = @geom.faces.length
    @buildSide @baseVertex.sw, @baseVertex.s, @baseVertex.se, @width, (i) -> i
    @buildSide @baseVertex.se, @baseVertex.e, @baseVertex.ne, @height, (i) => (i*@width+(@width-1))
    @buildSide @baseVertex.ne, @baseVertex.n, @baseVertex.nw, @width, (i) => (@width-i-1)+@width*(@height-1)
    @buildSide @baseVertex.nw, @baseVertex.w, @baseVertex.sw, @height, (i) => ((@width-i-1)*@width)
    @buildBottomCap();
    # Apply alternative material to the recently built faces
    for n in [faceIndex...@geom.faces.length]
      @geom.faces[n].materialIndex = 1

  buildUnderside: ->
    @firstUndersideVertex = @geom.vertices.length
    @buildTerrainMesh(true);

  indexOfUndersideVertexAt: (x,y) ->
    @firstUndersideVertex+x+y*@width

  indexOfTerrainVertexAt: (x,y) ->
    x+y*@width

  stitchTerrainToBottom: ->
    # North
    y = 0
    for x in [0...(@width-1)]
      @geom.faces.push(new THREE.Face3(@indexOfTerrainVertexAt(x, y), @indexOfTerrainVertexAt(x+1, y),   @indexOfUndersideVertexAt(x+1, y)))
      @geom.faces.push(new THREE.Face3(@indexOfTerrainVertexAt(x, y), @indexOfUndersideVertexAt(x+1, y), @indexOfUndersideVertexAt(x, y) ))
    # South
    y = @height-1
    for x in [0...(@width-1)]
      @geom.faces.push(new THREE.Face3(@indexOfTerrainVertexAt(x, y), @indexOfUndersideVertexAt(x+1, y), @indexOfTerrainVertexAt(x+1, y)  ))
      @geom.faces.push(new THREE.Face3(@indexOfTerrainVertexAt(x, y), @indexOfUndersideVertexAt(x, y),   @indexOfUndersideVertexAt(x+1, y)))
    # West
    x = 0
    for y in [0...(@height-1)]
      @geom.faces.push(new THREE.Face3(@indexOfTerrainVertexAt(x, y), @indexOfUndersideVertexAt(x, y+1), @indexOfTerrainVertexAt(x, y+1)  ))
      @geom.faces.push(new THREE.Face3(@indexOfTerrainVertexAt(x, y), @indexOfUndersideVertexAt(x, y),   @indexOfUndersideVertexAt(x, y+1)))
    # East
    x = @width-1
    for y in [0...(@height-1)]
      @geom.faces.push(new THREE.Face3(@indexOfTerrainVertexAt(x, y), @indexOfTerrainVertexAt(x, y+1),   @indexOfUndersideVertexAt(x, y+1)))
      @geom.faces.push(new THREE.Face3(@indexOfTerrainVertexAt(x, y), @indexOfUndersideVertexAt(x, y+1), @indexOfUndersideVertexAt(x, y)  ))



  # (re)builds the geometry(!)
  buildGeometry: ->
    @geom = new THREE.Geometry()
    @buildTerrainMesh()
    faceIndex = @geom.faces.length
    @buildUnderside()
    @stitchTerrainToBottom()
    for n in [faceIndex...@geom.faces.length]
      @geom.faces[n].materialIndex = 1
    #@buildBase()

  weightedAverageElevetion: (x,y,range) ->
    sum = 0
    count = 0
    for xOffset in [-range..range]
      for yOffset in [-range..range]
        xVertex = x+xOffset
        yVertex = y+yOffset
        continue if xVertex < 0 || xVertex >= @width || yVertex < 0 || yVertex >= @height
        sample = @geom.vertices[xVertex+yVertex*@width].y
        weight = (1 / (1+Math.abs(xOffset)/5) + 1 / (1+Math.abs(yOffset)/5))/2
        sum += sample*weight
        count += weight
    sum/count

  updateBottomShape: ->
    if @firstUndersideVertex?
      for x in [0...@width]
        for y in [0...@height]
          if @carveUnderside
            factor = 1-Math.pow(Math.abs(x-@width/2)/(@width/2),6)
            factor *= 1-Math.pow(Math.abs(y-@height/2)/(@height/2),6)
            factor -= 0.2
            factor = 0 if factor < 0
            @geom.vertices[@firstUndersideVertex+x+y*@width].y = @weightedAverageElevetion(x, y, 6)*factor-@baseThickness
          else
            @geom.vertices[@firstUndersideVertex+x+y*@width].y = -@baseThickness

  # Moves all terrain points down so that the lowest point is at y == 0.0
  eliminateBias: ->
    min = 9999999.0
    for n in [0...(@width*@height)]
      value = @geom.vertices[n].y
      min = value if value < min
    for n in [0...(@width*@height)]
      @geom.vertices[n].y -= min

  # Applies the elevation data to the mesh by reading the red-component from the pixels in the
  # canvas. image may be either a canvas, a DOM image, or a TerrainRawRez-instance. The provided
  # image _must_ have the same aspect ratio as the terrain model, or there will be glitches.
  applyElevation: (image, options = {}) ->
    # Make sure we have a geometry to elevate
    @buildGeometry() unless @geom?
    if image? && image.getSample?
      # This is a TerrainRawRez object
      for y in [0...@height]
        for x in [0...@width]
          value = image.getSample(x,y) || 0
          @geom.vertices[x+y*@width].y = value*(options.zScale||1.0)*@scale
    else
      # This is an image
      # Clear the scratch canvas
      @ctx.clearRect(0, 0, @width, @height)
      # Scale the provided image to the target canvas size
      @ctx.drawImage(image, 0, 0, @width, @height) if image?
      # Get the image data as raw binary
      pixels = @ctx.getImageData(0, 0, @width, @height).data
      # Use the values in each pixel to calculate an altitude for each terrain vertex and place it
      for n in [0...(@width*@height)]
        value = pixels[n*4]
        @geom.vertices[n].y = value*(options.zScale||1.0)*@scale
    @eliminateBias()
    @updateBottomShape()
    # These are required steps to make sure the mesh renders correctly
    @geom.computeFaceNormals()
    @geom.computeVertexNormals()
    @geom.verticesNeedUpdate = true
    @geom.normalsNeedUpdate = true
    @geom.computeBoundingSphere()

module.exports = TerrainBuilder
