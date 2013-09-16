require('coffee-script');
Fabricator = require('./fabricator');
fs = require('fs');

out_format = process.argv[2];
if(!out_format) {
  out_format = "stl"
}

console.log("Loading")
data = new Fabricator.TerrainData(704813.6707534629,7732087.294896157,726970.8883717663,7709930.077277854, 400, 400);
data.load(function(){
  console.log("Generating "+out_format+" mesh")
  mesh = new Fabricator.TerrainMesh(data);
  console.log("Saving mesh")
  fs.writeFileSync("./mesh."+out_format, eval("mesh.as"+out_format.toUpperCase()+"()"));
});


