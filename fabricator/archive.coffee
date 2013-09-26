TerrainData = require('./data.coffee')
TerrainMesh = require('./mesh.coffee')
config = require('../config/app.json')
httpGet = require('http-get')
exec = require('child_process').exec
mkdirp = require('mkdirp')
rimraf = require('rimraf')
fs = require('fs')
Canvas = require('canvas')
path = require('path')

class Archive
  # Options: {folder: <where to store, default a random place in /tmp>, terrainSamples: <number of samples along each dimension in the mesh>,
  # box: {nw: [northing, easting] (northwest corner), se: [northing, easting]} (southeast corner)}
  constructor: (@options) ->
    @options.terrainSamples ||= 324
    @options.filename ||= "/tmp/terrafab/"+Math.random().toString(36).substring(2)+'.zip'
    unless path.extname(@options.filename) == '.zip'
      @options.filename += '.zip'
    @options.folder = @options.filename.split('.').slice(0,-1).join('.')
    mkdirp.sync(@options.folder)
  _loadMesh: (callback) ->
    data = new TerrainData(@options.box.nw[0], @options.box.nw[1], @options.box.se[0], @options.box.se[1],
      @options.terrainSamples, @options.terrainSamples)
    console.log "Loading terrain data"
    data.load =>
      @mesh = new TerrainMesh(data, true) # Mesh with carved underside for color printers
      callback()
  _saveTexture: (callback) ->
    console.log "_saveTexture"
    boxParams = [@options.box.nw[0], @options.box.nw[1], @options.box.se[0], @options.box.se[1]].join(',')
    console.log "Getting texture"
    httpGetOpts =
      bufferType: "buffer"
      url: "#{config.imageUrl}/map?box=#{boxParams}&outsize=800,800&shading=true"
    console.log "Getting texture from: #{httpGetOpts.url}"
    httpGet.get httpGetOpts, (err, result) =>
      if err?
        console.log "Failed getting texture @ #{httpGetOpts.url}"
        console.log err
        process.exit(9)
      else
        console.log "Adding decals to texture"
        # Draws a white border on the texture
        img = new Canvas.Image()
        img.src = result.buffer
        withDecals = new Canvas(img.width, img.height)
        ctx = withDecals.getContext('2d')
        ctx.drawImage(img, 0, 0)
        ctx.strokeStyle = "#a3ac8f"
        ctx.lineCap = 'square'
        ctx.lineWidth = 7
        ctx.strokeRect(0,0,img.width-1, img.height-1)
        # Saves the modified texture
        filename = "#{@options.folder}/texture.png"
        console.log "Saving texture"
        fs.writeFileSync(filename, withDecals.toBuffer())
        callback(null, filename)
  # Deletes detritus generated while creating the archive
  cleanup: ->
    rimraf.sync(@options.folder)
  # Builds the archive
  build: (callback) ->
    return if @built?
    console.log "Building archive contents"
    meshDone = false
    textureDone = false
    doneHandler = =>
      if meshDone && textureDone
        meshText = @mesh.asX3D()
        console.log "Writing .x3d file"
        fs.writeFileSync("#{@options.folder}/terrain.x3d", meshText)
        console.log "Files ready to be archived"
        @built = true
        callback(null, true)
    @_saveTexture (err, filename) =>
      console.log "Texture done"
      textureDone = true
      doneHandler()
    @_loadMesh =>
      console.log "Terrain loaded"
      meshDone = true
      doneHandler()
  # Builds the archive then pipes the zip-archive to the provided stream. When done the callback is called
  # (err, exit_code)
  generate: (callback) ->
    @build (err, success) =>
      if err?
        callback(err, null)
      else
        cmd = "zip -rj #{@options.filename} #{@options.folder}/*"
        console.log "Executing: #{cmd}"
        zip = exec cmd, {}, (error, stdout, stderr) ->
          if error?
            console.log error
          if stderr?
            console.log "Stderr (#{stderr.length} bytes}"
            console.log(stderr.toString())
        zip.on 'exit', (code, signal) =>
          console.log "zip finished", code, signal
          @cleanup()
          if code != 0
            callback("Zip failed with exit code #{code}", null)
          else
            callback(null, @options.filename)

module.exports = Archive
