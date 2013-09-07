THREE = require "three"

class TerrainBuilder
  constructor: (@width, @height, @xyScale = 1.0, @zScale = 10.0) ->
    @canvas ||= document.createElement("canvas")
    @canvas.width = @width
    @canvas.height = @height
    @ctx = @canvas.getContext('2d')

  terrainCoordinateToVector: (x,y) ->
    new THREE.Vector3((x-@width/2)*@xyScale, 0, (y-@height/2)*@xyScale)
  terrainCoordinateToUV: (x,y) ->
    new THREE.Vector2(1.0*x / @width, 1.0*y / @height)
  terrainCoordinateToVertexIndex: (x,y) ->
    x+y*@width
  buildTerrainMesh: ->
  # builds the default mesh without applying any elevation
    # An array of texture coordinates in vertex order
    uvs = []
    # Add vertices for the terrain grid
    for y in [0...@height]
      for x in [0...@width]
        @geom.vertices.push(@terrainCoordinateToVector(x,y))
        # For each terrain vertex, also remember a corresponding UV coordinate for later
        uvs.push(@terrainCoordinateToUV(x,y))
    # Add all the faces for the terrain grid
    for row in [0...(@width-1)]
      for column in [0...(@height-1)]
        # Corners of the current quad
        top_left = column+row*@width
        top_right = top_left+1
        bottom_left = top_left+@width
        bottom_right = top_right+@width
        # Triangle one
        @geom.faces.push(new THREE.Face3(bottom_right, top_right, top_left))
        @geom.faceVertexUvs[0].push([uvs[bottom_right], uvs[top_right], uvs[top_left]])
        # Triangle two
        @geom.faces.push(new THREE.Face3(bottom_left, bottom_right, top_left))
        @geom.faceVertexUvs[0].push([uvs[bottom_left], uvs[bottom_right], uvs[top_left]])
  buildBottomVertices: ->
    # Generate the vertices of the bottom
    xMax = @width-1
    yMax = @height-1
    vertices = [
      @terrainCoordinateToVector(0,0)               # SW
      @terrainCoordinateToVector(xMax/2,0)        # S
      @terrainCoordinateToVector(xMax,0)          # SE
      @terrainCoordinateToVector(0,yMax/2)       # W
      @terrainCoordinateToVector(xMax,yMax/2)  # E
      @terrainCoordinateToVector(0, yMax)        # NW
      @terrainCoordinateToVector(xMax/2, yMax) # N
      @terrainCoordinateToVector(xMax, yMax)   # NE
    ]
    # Place all the base vertices a little bit below the water line
    vertex.y = -100 for vertex in vertices
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
    console.log arguments
    console.log @geom.vertices.length
    for n in [0...count-1]
      @geom.faces.push(new THREE.Face3(center, indexOfTerrainVertex(n), indexOfTerrainVertex(n+1)))
    @geom.faces.push(new THREE.Face3(center, left, indexOfTerrainVertex(0)))
    @geom.faces.push(new THREE.Face3(center, indexOfTerrainVertex(count-1), right))

  buildBase: ->
    @buildBottomVertices()
    faceIndex = @geom.faces.length
    @buildSide @baseVertex.sw, @baseVertex.s, @baseVertex.se, @width, (i) -> i
    @buildSide @baseVertex.se, @baseVertex.e, @baseVertex.ne, @height, (i) => (i*@width+(@width-1))
    @buildSide @baseVertex.ne, @baseVertex.n, @baseVertex.nw, @width, (i) => (@width-i-1)+@width*(@height-1)
    @buildSide @baseVertex.nw, @baseVertex.w, @baseVertex.sw, @height, (i) => ((@width-i-1)*@width)
    # Apply alternative material to the recently built faces
    for n in [faceIndex...@geom.faces.length]
      @geom.faces[n].materialIndex = 1

  buildGeometry: ->
    @geom = new THREE.Geometry()
    @buildTerrainMesh();
    @buildBase()

  # Applies the elevation data to the mesh by reading the red-component from the pixels in the
  # canvas.
  applyElevation: ->
    @buildGeometry() unless @geom?
    pixels = @ctx.getImageData(0, 0, @width, @height).data
    for n in [0...(@width*@height)]
      value = pixels[n*4+1]|(pixels[n*4]<<8)
      @geom.vertices[n].y = value*@zScale*@xyScale
    @geom.computeFaceNormals()
    @geom.computeVertexNormals()
    @geom.verticesNeedUpdate = true
    @geom.normalsNeedUpdate = true
  clear: ->
    @ctx.clearRect(0,0, @width, @height)

module.exports = TerrainBuilder