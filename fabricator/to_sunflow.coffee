# Generates a Sunflow Scene with the provided terrain

module.exports = (builder) ->
  result = "image {\n
      resolution 640 480\n
      aa 0 1\n
      filter mitchell\n
    }\n
    \n
    camera {\n
      type pinhole\n
      eye    -100 -100 40\n
      target 0.0554193 0.00521195 5.38209\n
      up     0 0 1\n
      fov    60\n
      aspect 1\n
    }\n
    \n
    light {\n
      type ibl\n
      image sky_small.hdr\n
      center 0 -1 0\n
      up 0 0 1\n
      lock true\n
      samples 200\n
    }\n
    \n
    shader {\n
      name default-shader\n
      type diffuse\n
      diff 0.25 0.25 0.25\n
    }\n
    modifier {\n
     name textureMap
     type normalmap
     texture \"./texture.png\"\n
    }\n"

  result += "object {\n
    shader default-shader\n
    type generic-mesh\n
    name terrain\n
    points #{builder.geom.vertices.length}\n"

  points = []
  for v in builder.geom.vertices
    points.push("      #{v.x} #{v.z} #{v.y}")
  result += points.join("\n")+"\n"
  points = null
  result += "triangles #{builder.geom.faces.length}\n"
  triangles = []
  normals = []
  for face in builder.geom.faces
    triangles.push("      #{face.a} #{face.b} #{face.c}")
    normals.push("      #{face.normal.x} #{face.normal.z} #{face.normal.y}")
  result += triangles.join("\n")+"\n"
  triangles = null
  result += "normals none\n"
  # result += "normals facevarying\n"
  # result += normals.join("\n")+"\n"
  normals = null
  result += "uvs vertex\n"
  for uv in builder.uvs
    result += "      #{1.0-uv.x} #{uv.y}\n"
  result += "}\n"
