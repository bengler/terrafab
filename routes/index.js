config = require("../config/app");
helpers = require("./helpers")
exec = require('child_process').exec;
fs = require('fs');
request = require('request');

ProductionServerUrl = "http://144.76.137.99:3000"

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

  // Set up system command
  var png_file = config.tmpFilePath+"/"+helpers.fileHash("dtm_"+box.join("_")+outsize.join('_'));
  var command = "bash -c 'gdal_translate -q -scale 0 550 -ot Byte -of PNG -outsize " +
    outsize[0] + " " + outsize[1] +
    " -projwin " + box.join(', ') +
    " " + dtm_file + " " + png_file + "'";

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
          console.log("Deferring to production server.")
          request.get(ProductionServerUrl+req.url).pipe(res);
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
  var png_file = config.tmpFilePath+"/"+helpers.fileHash("mapbox_"+box.join("_")+outsize.join('_'));
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
          // Try to serve the request by passing the request to a productino server
          request.get(ProductionServerUrl+req.url).pipe(res);
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
