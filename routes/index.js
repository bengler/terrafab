
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
  if(box == null) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    return res.send('{"error": "No box param given. Should be in format: ?box=253723.176600653,6660500.4670516,267723.176600653,6646500.4670516"}');
  }
  var outsize = req.query.outsize; // The output size of the tile
  if(outsize == null) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    return res.send('{"error": "No outsize param given. Should be in format: ?outsize=1000,1000  (x,y)"}');
  } else {
    outsize = outsize.split(",");
  }

  var png_file = "/tmp/"+box.join("_")+".png";
  var dtm_file = "/mnt/warez/dtm/dtm.vrt";
  var command = "bash -c 'gdal_translate -q -scale 0 550 -ot Byte -of PNG -outsize "+outsize[0]+" "+outsize[1]+" -projwin " + box.join(', ') + " "+dtm_file+" "+png_file+"'";

  var exec = require('child_process').exec;
  var fs = require('fs');

  function pipe(err,stdout, stderr) {
    if (err) {
      err.error = stderr
      res.send(err);
      return;
    }
    res.writeHead(200, {'Content-Type': 'image/png' });
    var img = fs.readFileSync(png_file);
    res.end(img, 'binary');
    fs.unlinkSync(png_file);
  }
  exec(command, pipe);
};
