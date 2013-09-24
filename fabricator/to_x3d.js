function toX3D(builder, name){

  var geometry = builder.geom
  var vertices = geometry.vertices;
  var faces    = geometry.faces;
  var uvs = builder.uvs;

  result = []
  result.push("<?xml version='1.0' encoding='UTF-8'?>");
  result.push("<X3D profile=\"Immersive\" version=\"3.1\">");
  result.push("<Scene>");
  result.push("<Shape>");
  result.push("<Appearance>");
  result.push("<ImageTexture url='texture.png'/>");
  result.push("</Appearance>");
  // Add indicies for triangles
  indicies = [];
  for(var i = 0; i<faces.length; i++){
    indicies.push([faces[i].a, faces[i].b, faces[i].c].join(' '));
  }
  result.push("<IndexedTriangleSet solid='false' index='"+indicies.join(' ')+"'>");
  // Add vertices
  points = [];
  for(var i = 0; i<vertices.length; i++){
    points.push(""+vertices[i].x+" "+(-vertices[i].z)+" "+vertices[i].y);
  }
  result.push("<Coordinate point='"+points.join(', ')+"'/>");
  // Add UV-map
  uvmap = [];
  for(var i= 0; i < uvs.length; i++) {
    uvmap.push(""+uvs[i].x+" "+uvs[i].y);
  }
  result.push("<TextureCoordinate point='"+uvmap.join(' ')+"'/>")
  result.push("</IndexedTriangleSet>");
  result.push("</Shape>");
  result.push("</Scene>");
  result.push("</X3D>");
  return result.join("\n");
}


module.exports = toX3D;
