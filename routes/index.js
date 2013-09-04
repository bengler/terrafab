
/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index', { title: 'Hello Terra!', version: require("../package.json").version });
};