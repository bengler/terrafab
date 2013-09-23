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
  fileName: ->
    config.files.tmpPath +
      "/"+helpers.fileHash(
          "dtm_"+@box.join("_")+[@xsamples,@ysamples].join('_'), 'bin')
  gdalCommand: ->
    dtm_file = config.lib.dtmFile;
    out_type = "UInt16"
    out_scale = "0 2469 0 32767"
    out_format = "ENVI"
    out_options = null
    return "bash -c '" +
      "gdal_translate -q" +
        " -scale " + out_scale +
        " -ot " + out_type +
        " -of " + out_format +
        " -outsize " + @xsamples + " " + @ysamples +
        " -projwin " + @box.join(', ') +
        " " + dtm_file + " " + @fileName() + "'"
  isLoaded: ->
    true
  getSample: (x, y) ->
    offset = (x+y*@xsamples)*2
    return @data[offset]|@data[offset+1]<<8

module.exports = TerrainData