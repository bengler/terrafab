var config = require("../config/app");
var helpers = require("./helpers")
var exec = require('child_process').exec;
var fs = require('fs');
var request = require('request');
var Archive = require('../fabricator/archive.coffee')

process.on('message', function(message) {
    // Process data

    process.send({id: message.id, data: 'some result'});
});

ShapeWaysClient = require('../fabricator/shapeways.coffee');
swClient = new ShapeWaysClient(
  config.shapewaysAPI.consumerKey,
  config.shapewaysAPI.consumerSecret,
  config.shapewaysAPI.callbackURL
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
  var fast_pipeline = true;
  switch(req.query.format) {
    case "bin":
      out_extension  = "bin";
      out_format = "ENVI";
      out_type = "UInt16";
      out_scale = "0 2469 0 32767";
      out_options = null
      out_content_type = {'Content-Type': 'application/octet-stream'};
      fast_pipeline = false;
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

  var command = false
  if (fast_pipeline) {
    command = "bash -c 'gdal_translate -q -outsize "+outsize[0]+' '+outsize[1]+" -a_srs EPSG:32633 -scale " + out_scale +
      " -ot "+out_type+" -of "+out_format+" -projwin +"+box.join(', ')+' '+dtm_file+' '+out_file+"'"
  } else {
    command = "bash -c '" +
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
  }
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
          if ((stderr.match('command not found') || stderr.match('No command') || stderr.match('does not exist in the file system') || stderr.match('Library not loaded'))) {
            console.log("Trying to get data from remote server at "+config.imageUrl+req.url);
            request.get(config.imageUrl+req.url).pipe(res);
            return;
          } else {
            console.error(err);
            res.status(500).send(stderr);
            return;
          }
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
 * GET UTM box texture tile.
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

  var withShading = (req.query.shading != null) && (req.query.shading != 'false')
  console.log("With shading?", withShading)

  var content_type = {'Content-Type': 'image/png'};
  var png_file = config.files.tmpPath+"/" +
    helpers.fileHash(
      "mapbox_"+box.join("_")+outsize.join('_'), "png"
    );

  var mapnikFile = config.lib.mapnikFile;

  if (withShading) {
    mapnikFile = config.lib.mapnikFileShading;
  }


  // Set up mapbox command
  var command = "bash -c '" + config.lib.mapboxScript +
      " -i " + mapnikFile +
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
    console.log("Running command: "+command)
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

/*
 * GET Download model as archive.
 */

exports.download = function(req, res) {
  var headers = {
    "Content-Type": "application/zip",
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
  var filename = config.files.tmpPath+"/"+Math.random().toString(36).substring(2)+'.zip';
  helpers.generate(filename, box, function(err, file) {
    if(err) {
      return res.status(500).end(err);
    }
    res.status(200).set(headers).cookie('fileDownload', 'true').sendfile(file);
  });
};


/*
 * GET The user's cart page where shipping to Shapeways will be done.
 *
 * This page makes sure the user can buy the model at Shapeways
 * It takes either box params or a modelId param for the Shapeways model.
 * User need to log into Shapeways first.
 */

exports.cart = function(req, res) {
  if(!req.query.box && !req.query.modelId) {
    return res.status(500).end("No box params or modelId given.");
  }
  if(req.query.modelId) {
    loginURL = '/login?redirect_url=' +
              encodeURIComponent('/cart?modelId=' +
                req.query.modelId
              );
  } else {
    loginURL = '/login?redirect_url=' +
              encodeURIComponent('/cart?box=' +
                req.query.box
              );
  }
  if(req.query.dev) {
    return res.render('cart', {
        title: 'Your cart',
        model: null,
        cart: {modelId: null, ready: false},
        version: require("../package.json").version
      }
    );
  }
  if(!helpers.isLoggedIn(req.session)) {
    res.redirect(loginURL);
  } else {
    // We have am modelId, meaning it is on Shapeways already.
    if(req.query.modelId) {
      swClient.getModel(
        req.query.modelId,
        config.shapewaysAPI.accessToken,
        config.shapewaysAPI.accessTokenSecret,
        function(err, model) {
          if(err) {
            console.error(err);
            if(err.statusCode != 500) {
              return res.redirect(loginURL);
            } else {
              console.log(err.statusCode);
              return res.status(err.statusCode || 500).end(JSON.stringify(err));
            }
          } else {
            ready = false;
            // The model is ready when it has a base price set by SW.
            if(model.materials[config.shapewaysAPI.defaultMaterialId].basePrice) {
              ready = true;
            }
            res.render('cart', {
                title: 'Your cart',
                model: model,
                cart: {modelId: model.modelId, ready: ready},
                version: require("../package.json").version
              }
            );
          }
        }
      );
    // No modelId. Box params should be present.
    } else {
      res.render('cart', {
          title: 'Your cart',
          model: null,
          cart: {ready: false},
          version: require("../package.json").version
        }
      );
    }
  }
};

/*
 * GET Sends the model to our our Shapeways account for analyzis and availablility.
 */
exports.shipToShapeways = function(req, res) {
  var box = helpers.boxFromParam(req.body.box, res);
  if(!box) {
    return;
  }
  if(!helpers.numericParams(box.concat(box), res)) {
    return;
  }
  var filename = config.files.tmpPath +
    "/"+
    helpers.fileHash(
        "shapeway_model_"+box.join("_"), '.zip');
  helpers.generate(filename, box, function(err, file) {
    if(err) {
      return res.status(500).end(err);
    }
    var modelOptions = config.shapewaysAPI.modelPostOptions;
    modelOptions.materials = {
      "26":{
        "markup": 0,
        "isActive": 1
      }
    };
    console.log("Posting model to Shapeways");
    if(req.cookie && req.cookie.modelId) {
      res.redirect('/cart?modelId=' + cookie.modelId);
    } else {
      swClient.postModel(
        file,
        modelOptions,
        config.shapewaysAPI.accessToken,
        config.shapewaysAPI.accessTokenSecret,
        function(err, result) {
          if(err) {
            console.error(err);
            return res.status(500).end(JSON.stringify(err));
          } else {
            console.log(result);
            res.status(200).cookie('modelId', result.modelId, { maxAge: 60 * 1000 })
            res.end('/cart?modelId=' +
                result.modelId
            );
            res.end(JSON.stringify({cartURL: '/cart?modelId=' + result.modelId}));
          }
        }
      );
    }
  });
};

/*
 * GET modeldata for model on Shapeways and return cart JSON for the cart page to poll.
 */

exports.cartData = function(req, res) {
  if(!req.session || !req.session.oauth_access_token) {
    return res.send(403, "No shapeway session!");
  }
  swClient.getModel(
    req.query.modelId,
    config.shapewaysAPI.accessToken,
    config.shapewaysAPI.accessTokenSecret,
    function(err, model) {
      if(err) {
        console.error(err);
        res.status(500).end(JSON.stringify(err));
      } else {
        var basePrice = model.materials[config.shapewaysAPI.defaultMaterialId].basePrice;
        if(basePrice) {
          basePrice = parseFloat(basePrice);
          var markupPrice = config.shapewaysAPI.defaultPrice - basePrice;
          swClient.updateModel(
            model.modelId,
            {
              "isPublic": 1,
              "materials": {
                "26": {
                  "markup": markupPrice,
                  "isActive": 1
                }
              }
            },
            config.shapewaysAPI.accessToken,
            config.shapewaysAPI.accessTokenSecret,
            function(err, result) {
              if(err) {
                console.error("Could not update markup price", err);
                res.status(500).end(JSON.stringify(err));
              } else {
                var cart = {
                  ready: (basePrice != 0),
                  modelId: model.modelId,
                  materialId: config.shapewaysAPI.defaultMaterialId,
                  orderPrice: config.shapewaysAPI.defaultPrice,
                  basePrice: parseFloat(basePrice),
                  markupPrice: markupPrice
                }
                res.end(JSON.stringify(cart));
              }
            }
          );
        } else {
          res.end(JSON.stringify({modelId: model.modelId}));
        }
      }
    }
  );
};

/*
 * Add the model to the user's cart (on Shapeways) through the SW API.
 * Will respond 500 until the model is read by SW.
 */

exports.addToCart = function(req, res) {
  if(!req.session || !req.session.oauth_access_token) {
    return res.send(403, "No shapeway session!");
  }
  swClient.addToCart(
    req.body.modelId,
    req.body.materialId,
    1,
    req.session.oauth_access_token,
    req.session.oauth_access_token_secret,
    function(err, result) {
      if(err) {
        res.status(500).end(JSON.stringify(err));
      } else {
        res.end(JSON.stringify({cartURL: 'https://www.shapeways.com/cart/'}))
      }
    }
  );
};


// oAuth routes

/*
 * GET Let us login to Shapeways to get an access token for the Terrafab Shapeways application.
 */
exports.login = function(req, res) {
  req.session.redirect_url = req.query.redirect_url
  swClient.login(function(err, callback) {
    req.session.oauth_token = callback.oauth_token;
    req.session.oauth_token_secret = callback.oauth_token_secret;
    res.redirect(callback.url);
  });
};

/*
 * GET Callback redirected to from Shapeways after authorization of our Shapeways application.
 */
exports.callbackFromShapeways = function(req, res) {
  console.log(req.query);
  return swClient.handleCallback(req.query.oauth_token, req.session.oauth_token_secret, req.query.oauth_verifier, function(callback) {
    req.session.oauth_access_token = callback.oauth_access_token;
    req.session.oauth_access_token_secret = callback.oauth_access_token_secret;
    redirectUrl = req.session.redirect_url;
    if(redirectUrl) {
      return res.redirect(redirectUrl);
    } else {
      return res.redirect("/");
    }
  });
};

/*
 * GET Just a text with the access token and secret.
 * These keys are to be put manually into our ./config/app.json
 * and act as us (not the user) in the Shapeways API (posting models to our account, etc).
 */
exports.accessToken = function(req, res) {
  if(!helpers.isLoggedIn(req.session)) {
    res.redirect('/login');
  } else {
    res.end("Your ouath access token:          " + req.session.oauth_access_token +
      "\nYour oauth access token secret:   " + req.session.oauth_access_token_secret +
      "\n\nThis ought to be put as 'accessToken' and 'accessTokenSecret' in your ./config/app.json under the 'shapewaysAPI' key");
  }
};
