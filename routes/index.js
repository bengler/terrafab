config = require("../config/app");
helpers = require("./helpers")
exec = require('child_process').exec;
fs = require('fs');
request = require('request');

/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index', { title: 'Hello Terra!', version: require("../package.json").version });
};


/*
 * GET DTM data.
 */

exports.dtm = function(req, res){

  // Guards
  var dtm_file = config.dtmFile;
  var box = helpers.boxFromParam(req.query.box, res);
  if(!box) {
    return;
  }
  var outsize = helpers.outsizeFromParam(req.query.outsize, res);
  if(!outsize) {
    return;
  }
  if(!helpers.numericParams(outsize.concat(box), res)) {
    return;
  }
  var outformat;
  var out_extension;
  var out_type;
  var out_header;
  var scale;
  switch(req.query.format) {
    case "bin":
      out_extension  = "bin";
      out_format = "ENVI";
      out_type = "UInt16";
      scale = "0 2469 0 32767";
      out_content_type = {'Content-Type': 'application/octet-stream' };
      break;
    default:
      out_extension  = "png";
      out_format = "PNG";
      out_type = "Byte";
      scale = "0 2469";
      out_content_type = {'Content-Type': 'image/png' };
  }
  // Set up system command
  var out_file = config.tmpFilePath+"/"+helpers.fileHash("dtm_"+box.join("_")+outsize.join('_'), out_extension);

  var command = "bash -c 'gdal_translate -q -scale "+scale+" -ot "+out_type+" -of "+out_format+" -outsize " +
    outsize[0] + " " + outsize[1] +
    " -projwin " + box.join(', ') +
    " " + dtm_file + " " + out_file + "'";

  if(config.cacheImages && fs.existsSync(out_file)) {
    // Output cached file
    res.writeHead(200, out_content_type);
    var img = fs.readFileSync(out_file);
    res.end(img, 'binary');
  } else {
    // Generate file
    exec(command, function (err, stdout, stderr) {
        if (err) {
          console.error(err);
          request.get(config.AlternativePngUrl+req.url).pipe(res);
          return;
        }
        res.writeHead(200, out_content_type);
        var img = fs.readFileSync(out_file);
        res.end(img, 'binary');
        if(!config.cacheImages) {
          fs.unlinkSync(out_file);
        }
      }
    );
  }
};


/*
 * GET UTM box.
 */

exports.map = function(req, res){

  // Guards
  var box = helpers.boxFromParam(req.query.box, res);
  if(!box) {
    return;
  }
  var outsize = helpers.outsizeFromParam(req.query.outsize, res);
  if(!outsize) {
    return;
  }
  if(!helpers.numericParams(outsize.concat(box), res)) {
    return;
  }

  // Set up system command
  var png_file = config.tmpFilePath+"/"+helpers.fileHash("mapbox_"+box.join("_")+outsize.join('_'), "png");
  var command = "bash -c '"+config.mapboxScript+" -i "+config.mapnikFile+" -o "+png_file+" --outsize "+outsize.join(',')+" --box "+box.join(',')+"'";
  if(config.cacheImages && fs.existsSync(png_file)) {
    // Output cached file
    res.writeHead(200, {'Content-Type': 'image/png' });
    var img = fs.readFileSync(png_file);
    res.end(img, 'binary');
  } else {
    // Generate file
    exec(command, function (err, stdout, stderr) {
        if (err) {
          console.error(err);
          console.log("Deferring to production server")
          request.get(config.AlternativePngUrl+req.url).pipe(res);
          return;
        }
        res.writeHead(200, {'Content-Type': 'image/png' });
        var img = fs.readFileSync(png_file);
        res.end(img, 'binary');
        if(!config.cacheImages) {
          fs.unlinkSync(png_file);
        }
      }
    );
  }
};
