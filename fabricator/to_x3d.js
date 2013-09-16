var THREE = require("three");

// function stringifyVector(vec){
//   return ""+vec.x+" "+vec.z+" "+vec.y;
// }

// function stringifyVertex(vec){
//   return "vertex "+stringifyVector(vec)+" \n";
// }

function toX3D(geometry, name){
  var vertices = geometry.vertices;
  var tris     = geometry.faces;

  geometry = THREE.GeometryUtils.triangulateQuads( geometry );

  x3d = {};
  x3d.doc = "<?xml version='1.0' encoding='UTF-8'?>\n<X3D profile='Immersive' version='3.2'\n\
    xmlns:xsd='http://www.w3.org/2001/XMLSchema-instance'\n\
    xsd:noNamespaceSchemaLocation='http://www.web3d.org/specifications/x3d-3.2.xsd'>\n";
  x3d.header = "\n\
    <head>\n\
      <meta content='"+name+".x3d' name='title'/>\n\
      <meta content='Export from Terrafab' name='description'/>\n\
      <meta content='"+(new Date()).toString()+"' name='created'/>\n\
      <meta content='"+(new Date()).toString()+"' name='modified'/>\n\
      <meta content='Bengler TerraFab' name='creator'/>\n\
      <meta content='http://terrafab.bengler.no' name='reference'/>\n\
      <meta content='http://terrafab.bengler.no/models/"+name+".x3d' name='identifier'/>\n\
      <meta content='http://terrafab.bengler.no/models/img/"+name+".png' name='image'/>\n\
      <meta content='http://terrafab.bengler.no/models/license' name='license'/>\n\
      <meta content='Bengler TerraFab, http://terrafab.bengler.no' name='generator'/>\n\
    </head>\n";

  x3d.scene = "\n\
    <Scene>\n\
      <Group>\n\
        <Viewpoint centerOfRotation='0 -1 0' description='Hello world!' position='0 -1 7'/>\n\
        <Transform rotation='0 1 0 3'>\n\
          <Shape>\n\
            <Sphere/>\n\
            <Appearance>\n\
              <Material diffuseColor='0 0.5 1'/>\n\
              <ImageTexture url='\"texture.png\"'/>\n\
            </Appearance>\n\
          </Shape>\n\
        </Transform>\n\
    </Scene>\n\n"
  // for(var i = 0; i<tris.length; i++){
  //   stl += ("facet normal "+stringifyVector( tris[i].normal )+"\n");
  //   stl += ("outer loop\n");
  //   stl += stringifyVertex( vertices[ tris[i].a ]);
  //   stl += stringifyVertex( vertices[ tris[i].c ]);
  //   stl += stringifyVertex( vertices[ tris[i].b ]);
  //   stl += ("endloop\n");
  //   stl += ("endfacet\n");
  // }
  // stl += ("endsolid model\n");

  return x3d.doc+x3d.header+x3d.scene+'</X3D>\n';
}

module.exports = toX3D;
