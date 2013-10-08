var cluster = require('cluster');
var express = require('express'), cookieSessions = require('./cookie-sessions.js');

require('coffee-script')


var routes = require('./routes');
var http = require('http');
var path = require('path');
var browserify = require('browserify-middleware');


var numCPUs = require('os').cpus().length;
var numWorkers = numCPUs * 2;

if (cluster.isMaster) {
  // Fork workers.
  for (var i = 0; i < numWorkers; i++) {
    cluster.fork();
  }
  cluster.on('exit', function (worker, code, signal) {
    console.log('worker ' + worker.process.pid + ' died');
  });
}
else {
  
  var app = express();

  app.use(function(req, res, next) {
    if (req.host == 'terrafab.no') {
      res.redirect('http://terrafab.bengler.no');
      res.end();
    }
  });

// all environments
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.cookieParser('terrafabshapeways'));
  app.use(cookieSessions('shapewaysterrafab'));
  app.use(app.router);
  app.use(require('stylus').middleware(__dirname + '/public'));
  app.use(express.compress());
  app.use(express.staticCache())
  app.use(express.static(path.join(__dirname, 'public')));

//provide browserified versions of all the files in a directory
  app.use('/js', browserify('./client', {
    grep: /\.(?:js|coffee)$/,
    transform: ['caching-coffeeify', 'brfs'],
    noParse: ['three', 'jquery']
  }));

// development only
  if ('development' == app.get('env')) {
    app.use(express.errorHandler());
  }

  app.get('/', routes.index);

// API routes
  app.get('/dtm', routes.dtm);
  app.get('/map', routes.map);

// Model routes
  app.get('/preview', routes.preview);
  app.get('/download', routes.download);

// Shapeways integration
  app.get('/cart', routes.cart);
  app.get('/cartdata', routes.cartData);
  app.post('/ship', routes.shipToShapeways);
  app.post('/addtocart', routes.addToCart);

// oAuth Bonanza
  app.get('/login', routes.login);
  app.get('/accesstoken', routes.accessToken);
  app.get('/callback', routes.callbackFromShapeways);

  http.createServer(app).listen(app.get('port'), function(){
    console.log('Express server listening on port ' + app.get('port'));
  });

}