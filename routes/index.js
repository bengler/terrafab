
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

  var box = req.query.box.split(','); // The bounding box from query
  var exec = require('child_process').exec;

  function pipe(err,stdout, stderr) {
    if (err) {
      err.error = stderr
      res.send(err);
    }
    res.send(stdout);
  }

  exec("gdal_translate -scale 0 550 -of PNG -outsize 2000 2000 -projwin "+box.join(', ')+" /mnt/warez/dtm/dtm.vrt >(tee /tmp/dtm.png)", pipe);
};
