
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
  var fs = require('fs');
  var filename = "/tmp/"+box.join("_")+".png";
  function pipe(err,stdout, stderr) {
    if (err) {
      err.error = stderr
      res.send(err);
      return;
    }
    res.writeHead(200, {'Content-Type': 'image/png' });
    var img = fs.readFileSync(filename);
    res.end(img, 'binary');
    fs.unlinkSync(filename);
  }
  var command = "bash -c 'gdal_translate -q -scale 0 550 -ot Byte -of PNG -outsize 2000 2000 -projwin " + box.join(', ') + " /mnt/warez/dtm/dtm.vrt "+filename+"'"
  exec(command, pipe);
};
