require('coffee-script');
Fabricator = require('./fabricator');
fs = require('fs');

console.log("Loading")
data = new Fabricator.TerrainData(704813.6707534629,7732087.294896157,726970.8883717663,7709930.077277854, 400, 400);
data.load(function(){
	console.log("Generating")
	mesh = new Fabricator.TerrainMesh(data);
	console.log("Saving mesh")
	fs.writeFileSync("./mesh.stl", mesh.asSTL());
});

