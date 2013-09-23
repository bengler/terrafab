config = require("../config/app");
helpers = require("../routes/helpers")
exec = require('child_process').exec;
httpGet = require('http-get')
config = require("../config/app");

class TerrainData
  constructor: (nwNorthing, nwEasting, seNorthing, seEasting, @xsamples, @ysamples) ->
    @box = [nwNorthing, nwEasting, seNorthing, seEasting]
  width: ->
    Math.abs(@box[0]-@box[2])
  height: ->
    Math.abs(@box[1]-@box[3])
  load: (onload) ->
    httpGetOpts =
      bufferType: "buffer"
      url: config.imageUrl+"/dtm?box=#{@box.join(',')}&outsize=#{@xsamples},#{@ysamples}&format=bin"
    console.log "Loading terrain data from #{httpGetOpts.url}"
    httpGet.get httpGetOpts, (err, result) =>
      if err?
        console.log err
      else
        console.log "Terrain data loaded"
        @data = result.buffer
        onload()
  isLoaded: ->
    true
  getSample: (x, y) ->
    offset = (x+y*@xsamples)*2
    return @data[offset]|@data[offset+1]<<8

module.exports = TerrainData