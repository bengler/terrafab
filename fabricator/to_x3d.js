var THREE = require("three");

function coordFromVector(vec){
  return ""+vec.x+" "+vec.z+" "+vec.y;
}

function toX3D(geometry, name){
  var vertices = geometry.vertices;
  var faces    = geometry.faces;

  geometry = THREE.GeometryUtils.triangulateQuads( geometry );

  x3d = {};
  x3d.doc = "<?xml version='1.0' encoding='UTF-8'?>\n<X3D profile='Immersive' version='3.2'\n\
    xmlns:xsd='http://www.w3.org/2001/XMLSchema-instance'\n\
    xsd:noNamespaceSchemaLocation='http://www.web3d.org/specifications/x3d-3.2.xsd'>\n";
  x3d.header = "\n\
    <head>\n\
      <meta content='"+name+".x3d' name='title'/>\n\
      <meta content='X3D export from Bengler Terrafab' name='description'/>\n\
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
    <Scene>\n"
        x3d.scene += "         <Shape>\n\
            <IndexedTriangleSet solid='false' index='";
        indicies = [];
        for(var i = 0; i<faces.length; i++){
          indicies.push([faces[i].a, faces[i].c, faces[i].b].join(' '));
        }
        x3d.scene += indicies.join(' ');
        x3d.scene += "'>\n";
        x3d.scene += "              <Coordinate point='";
        points = [];
        for(var i = 0; i<vertices.length; i++){
          points.push(coordFromVector(vertices[i]));
        }
        x3d.scene += points.join(', ')
        x3d.scene += "'/>\n";
        x3d.scene += "            </IndexedTriangleSet>\n";
        x3d.scene += "         </Shape>\n";
  x3d.scene += "\
    </Scene>\n\n";
  return x3d.doc+x3d.header+x3d.scene+'</X3D>\n';
}


module.exports = toX3D;
