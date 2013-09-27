var crypto = require("crypto");
var exec = require('child_process').exec;
var fs = require('fs');
var execSync = require('exec-sync');

helpers = {

  boxFromParam: function (param, res) {
    var box = null
    if(param == null) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end('{"error": "No box param given. Should be in format: '+
        '?box=253723.176600653,6660500.4670516,267723.176600653,6646500.4670516"}');
      return;
    } else {
      param = param.split("|")[0];
      box = param.split(',');
    }
    if (parseFloat(box[0]) > parseFloat(box[2])) {
      console.log("Swapped box 0 <-> 2 because "+box[0]+" is more than "+box[2])
      p = box[2]
      box[2] = box[0]
      box[0] = p
    }
    if (parseFloat(box[1]) < parseFloat(box[3])) {
      p = box[3]
      box[3] = box[1]
      box[1] = p
      console.log("Swapped box 1 <-> 3")
    }
    return box;
  },

  outsizeFromParam: function(param, res) {
    var outsize = null;
    if(param == null) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end('{"error": "No outsize param given. ' +
        'Should be in format: ?outsize=1000,1000  (x,y)"}');
      return false;
    } else {
      outsize = param.split(",");
      if(outsize.length == 1) {
        outsize = [outsize,outsize];
      }
    }
    return outsize;
  },
  numericParams: function(params, res) {
  	var non_number = false;
  	params.forEach(function(i) {
  	      if(!(typeof Number(i) === 'number' &&
              isFinite(Number(i)))) {
  	        non_number = i;
  	        return;
  	      }
  	    }
  	  );
    if(non_number) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end('{"error": "box or outsize param contains non-numerics"}');
    }
    return !non_number;
  },
  fileHash: function(filename, extension) {
    return crypto.createHash('sha1').update(filename).digest('hex')+"."+extension;
  },
  isLoggedIn: function(session) {
    if (!session.oauth_access_token) {
      return false;
    }
    return true;
  },
  generate: function(filename, box, callback) {
    if(fs.existsSync(filename)) {
      console.log("generator: Using cached archive");
      return callback(null, filename);
    }
    var output = "";
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
        callback("Generator failed with code "+code+"\n <!-- "+output+" -->", null);
      } else {
        callback(null, filename);
      }
    });
  },
  generateSync: function(filename, box, callback) {
    if(fs.existsSync(filename)) {
      console.log("generator: Using cached archive");
      return callback(null, filename);
    }
    var output = "";
    var generator = execSync("node "+__dirname+"/../generate.js "+filename+" \""+box.join(',')+"\"", function(err, stdout, stderr) {
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
        return callback(output, null);
      }
    });
    callback(null, filename);
  }
};

module.exports = helpers;
