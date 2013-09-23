# The command line utility to generate terrain archives for shapeways etc.
# usage: node generate.js outfile.zip "124675.69497915338,6951013.442363326,129414.02050493869,6946275.116837542"
Archive = require('../fabricator/archive.coffee')

outfile = process.argv[2]
box = process.argv[3].split(/\s*,\s*/)

console.log "Generating terrain mesh for area #{box.join(',')} writing archive to #{outfile}."

zip = new Archive({filename: outfile, box: {nw: [box[0], box[1]], se: [box[2], box[3]]}})
zip.generate (err, filename) ->
  if (err)
  	console.log err
  	process.exit(9)
  else
  	console.log "Success!"
  	process.exit(0)
