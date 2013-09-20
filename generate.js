require('coffee-script');
Fabricator = require('./fabricator');
fs = require('fs');

out_format = process.argv[2];
if(!out_format) {
  out_format = "stl"
}

SAMPLES_PER_SIDE = 324

console.log("Loading")
//124050.91512455678,6951913.421439983,128938.89691349023,6947025.43965105

data = new Fabricator.TerrainData(124675.69497915338,6951013.442363326,129414.02050493869,6946275.116837542, SAMPLES_PER_SIDE, SAMPLES_PER_SIDE);
data.load(function(){
  console.log("Building "+out_format+" mesh")
  mesh = new Fabricator.TerrainMesh(data);
  console.log("Exporting")
  fs.writeFileSync("./mesh."+out_format, eval("mesh.as"+out_format.toUpperCase()+"()"));
});


//curl "http://localhost:3000/map?box=124675.69497915338,6951013.442363326,129414.02050493869,6946275.116837542&outsize=2000,2000"