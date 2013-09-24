var config = require("../config/app");
var helpers = require("./helpers")
var exec = require('child_process').exec;
var fs = require('fs');
var request = require('request');
var Archive = require('../fabricator/archive.coffee')

ShapeWaysClient = require('../fabricator/shapeways.coffee');
swClient = new ShapeWaysClient(
  config.shapewaysAPI.consumerKey,
  config.shapewaysAPI.consumerSecret
);

/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index', {
      title: 'Terrafab',
      version: require("../package.json").version
    }
  );
};

/*
 * GET preview page.
 */

exports.preview = function(req, res){
  res.render('preview', {
      title: 'Preview model',
      version: require("../package.json").version
    }
  );
};


/*
 * GET DTM data.
 */

exports.dtm = function(req, res){

  // Guards
  var dtm_file = config.lib.dtmFile;
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

  // File generation with gdal_translate
  var out_format;
  var out_extension;
  var out_type;
  var out_scale;
  switch(req.query.format) {
    case "bin":
      out_extension  = "bin";
      out_format = "ENVI";
      out_type = "UInt16";
      out_scale = "0 2469 0 32767";
      out_options = null
      out_content_type = {'Content-Type': 'application/octet-stream'};
      break;
    default:
      out_extension  = "png";
      out_format = "PNG";
      out_type = "Byte";
      out_scale = "0 2469 0 255";
      out_options = null;
      out_content_type = {'Content-Type': 'image/png'};
  }
  // Set up gdal_translate command
  var out_file = config.files.tmpPath +
    "/"+
    helpers.fileHash(
        "dtm_"+box.join("_")+outsize.join('_'), out_extension);

  var tif_file = out_file.replace('.'+out_extension, '.tif');

  var command = "bash -c '" +
      "GDAL_CACHEMAX=1000 gdalwarp -wm 1000 -s_srs EPSG:32633 -t_srs EPSG:32633" +
      " -r cubic -ts "+ outsize[0] + " " + outsize[1] +
      " -of GTiff " +
      "-te " + [box[0], box[3], box[2], box[1]].join(' ') + " " +
      dtm_file + " " + tif_file +
      " && " +
      "gdal_translate -q" +
        " -scale " + out_scale +
        " -ot " + out_type +
        (out_options ? " -co " + out_options + " " : "") +
        " -of " + out_format +
//      " -outsize " + outsize[0] + " " + outsize[1] +
        " -projwin " + box.join(', ') +
        " " + tif_file + " " + out_file +
      " && rm " + tif_file +"'";
  console.log("Running command:" + command);

  // Output cached file if exists
  if(config.files.cache && fs.existsSync(out_file)) {
    res.writeHead(200, out_content_type);
    var img = fs.readFileSync(out_file);
    res.end(img, 'binary');
  } else {
    // Generate file
    exec(command, function (err, stdout, stderr) {
        if (err) {
          if(stderr && stderr.match(
            'Computed -srcwin falls outside raster size')) {
              res.writeHead(404);
              res.end(stderr);
              return;
          }
          console.error(err);
          console.log("Trying to get data from remote server at "+config.imageUrl+req.url);
          request.get(config.imageUrl+req.url).pipe(res);
          return;
        }
        res.writeHead(200, out_content_type);
        var img = fs.readFileSync(out_file);
        res.end(img, 'binary');
        if(!config.files.cache) {
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

  var content_type = {'Content-Type': 'image/png'};
  var png_file = config.files.tmpPath+"/" +
    helpers.fileHash(
      "mapbox_"+box.join("_")+outsize.join('_'), "png"
    );

  // Set up mapbox command
  var command = "bash -c '" + config.lib.mapboxScript +
      " -i " + config.lib.mapnikFile +
      " -o "+png_file +
      " --outsize "+outsize.join(',') +
      " --box "+box.join(',') +
    "'";

  if(config.cache && fs.existsSync(png_file)) {
    // Output cached file
    res.writeHead(200, content_type);
    var img = fs.readFileSync(png_file);
    res.end(img, 'binary');
  } else {
    // Generate file
    exec(command, function (err, stdout, stderr) {
        if (err) {
          console.error(err);
          console.log("Deferring to production server")
          request.get(config.imageUrl+req.url).pipe(res);
          return;
        }
        res.writeHead(200, content_type);
        var img = fs.readFileSync(png_file);
        res.end(img, 'binary');
        if(!config.cache) {
          fs.unlinkSync(png_file);
        }
      }
    );
  }
};

exports.download = function(req, res) {
  var headers = {
    "Content-Type": "application/force-download",
    "Content-Disposition": "attachment; filename=\"terrain-model.zip\""
  };
  var box = []
  var _ref = helpers.boxFromParam(req.query.box, res);
  // Protect against injection attacks
  var _i, _len
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    var value = _ref[_i];
    box.push(parseFloat(value))
  }
  var filename = "/tmp/terrafab/"+Math.random().toString(36).substring(2)+'.zip'
  var output = ""
  var generator = exec("node "+__dirname+"/../generate.js "+filename+" \""+box.join(',')+"\"", function(err, stdout, stderr) {
    if (err) {
      output += err;
    };
    if (stdout) {
      console.log("generator: ", stdout.toString())
      output += stdout.toString();
    };
    if (stderr) {
      console.log("generator: ", stderr.toString())
      output += stderr.toString();
    }
  });
  generator.on('exit', function(code, signal) {
    if (code != 0) {
      res.status(500).send("Generator failed with code "+code+"\n <!-- "+output+" -->");
    } else {
      res.status(200).set(headers).sendfile(filename)
    }
  })
}

/*
 * GET Let us login to Shapeways to get an access token for the Terrafab Shapeways application.
 */
exports.login = function(req, res) {
  swClient.login(function(err, callback) {
    req.session.oauth_token = callback.oauth_token;
    req.session.oauth_token_secret = callback.oauth_token_secret;
    res.redirect(callback.url);
  });
};

/*
 * GET Callback called from Shapeways after the user (us) has accepted the Shapeways Terrafab application.
 */
exports.callback = function(req, res) {
  return swClient.handleCallback(req.query.oauth_token, req.session.oauth_token_secret, req.query.oauth_verifier, function(callback) {
    req.session.oauth_access_token = callback.oauth_access_token;
    req.session.oauth_access_token_secret = callback.oauth_access_token_secret;
    return res.redirect('/session');
  });
};

/*
 * GET Just shows the access token and access secret to be put manually in app.json
 */
exports.session = function(req, res) {
  if(!helpers.isLoggedIn(req.session)) {
    res.redirect('/login');
  } else {
    res.end("Your session: "+JSON.stringify(req.session));
  }
};

/*
 * POST Send a model to shapeways.
 */
exports.toShapeways = function(req, res) {
  var box = helpers.boxFromParam(req.query.box, res);
  if(!box) { return; }
  // JUST DUMMY FOR NOW:
  target = swClient.postModel(
    "/tmp/terrafab/uoo284ss6ymsra4i.zip",
    config.shapewaysAPI.accessToken,
    config.shapewaysAPI.accessTokenSecret,
    function(err, result) {
      console.log(err, result);
      if(err) {
        res.status(500).end(err);
      } else {
        res.status(200).end(result);
      }
    }
  );
};
