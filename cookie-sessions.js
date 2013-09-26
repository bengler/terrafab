// https://gist.github.com/visionmedia/1491756
module.exports = function(name) {
  return function(req, res, next) {
    req.session = req.signedCookies[name] || {};

    res.on('header', function(){
      res.cookie(name, req.session, { signed: true, expires: new Date(Date.now() + 30000) });
    });

    next();
  }
}
