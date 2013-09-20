TerrainData = require('./data.coffee')
TerrainMesh = require('./mesh.coffee')
config = require('../config/app.json')
http = require('http-get')
exec = require('child_process').exec
mkdirp = require('mkdirp')
rimraf = require('rimraf')

class Archive
  # Options: {folder: <where to store, default a random place in /tmp>, terrainSamples: <number of samples along each dimension in the mesh>,
  # box: {nw: [northing, easting] (northwest corner), se: [northing, easting]} (southeast corner)}
  constructor: (@options) ->
    @options.terrainSamples ||= 324
    @options.folder ||= "/tmp/terrafab/"+Math.random().toString(36).substring(2)
    mkdirp.sync(@options.folder)
  # Builds the meshes. One in color for gypsum-based printing, and one monochrome in STL-format for deposition printing
  _saveMeshSync: ->
    data = new TerrainData(@options.box.nw[0], @options.box.nw[1], @options.box.sw[0], @options.box.sw[1],
      @options.terrainSamples, @options.terrainSamples)
    mesh = new Fabricator.TerrainMesh(data, true) # Mesh with carved underside for color printers
    fs.writeFileSync("#{@options.folder}/terrain.x3d", mesh.asX3D())
    # mesh = new Fabricator.TerrainMesh(data, false) # Mesh with flat bottom for makerbots etc.
    # fs.writeFileSync("#{@options.folder}/terrain.stl", mesh.asSTL())
  # Fetches the texture and sticks it in the archive. Callback: (err, filename)
  _saveTexture: (callback) ->
    boxParams = [@options.box.nw[0], @options.box.nw[1], @options.box.sw[0], @options.box.sw[1]]
    httpGetOpts =
      bufferType: "buffer"
      url: "#{config.imageUrl}/map?box=#{boxParams}&outsize=2000,2000"
    http.get httpGetOpts, (err, result) =>
      if err?
        console.log "Failed getting texture @ #{httpGetOpts.url}"
        console.log err
        callback(err, null)
      else
        filename = "#{@options.folder}/texture.png"
        fs.writeFileSync(filename)
        callback(null, filename)
  # Deletes all files associated with this archive
  delete: ->
    rimraf.sync(@options.folder)
  # Builds the archive
  build: (callback) ->
    return if @built?
    @_saveMeshSync()
    @_saveTexture (err, filename) =>
      @built = true
      callback(err, filename?)
  # Builds the archive then pipes the zip-archive to the provided stream. When done the callback is called
  # (err, exit_code)
  write: (stream, callback) ->
    @build (err, success) =>
      if err?
        callback(err, null)
      else
        zip = exec("zip -rj - #{@options.folder}")
        zip.stdout.pipe(stream)
        zip.on 'exit', (code, signal) ->
          @delete()
          callback(null, code)







