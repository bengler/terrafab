var THREE = require("three");

function stringifyVector(vec){
  return ""+vec.x+" "+vec.z+" "+vec.y;
}

function stringifyVertex(vec){
  return "vertex "+stringifyVector(vec)+" \n";
}

function toSTL(geometry){
  var vertices = geometry.vertices;
  var tris     = geometry.faces;

  geometry = THREE.GeometryUtils.triangulateQuads( geometry );

  stl = "solid model\n";
  for(var i = 0; i<tris.length; i++){
    stl += ("facet normal "+stringifyVector( tris[i].normal )+"\n");
    stl += ("outer loop\n");
    stl += stringifyVertex( vertices[ tris[i].a ]);
    stl += stringifyVertex( vertices[ tris[i].c ]);
    stl += stringifyVertex( vertices[ tris[i].b ]);
    stl += ("endloop\n");
    stl += ("endfacet\n");
  }
  stl += ("endsolid model\n");

  return stl;
}

module.exports = toSTL;