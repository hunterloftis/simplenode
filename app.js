var express = require('express');
var timeout = require('connect-timeout');
var stylus = require('stylus');
var path = require('path');
var _ = require('underscore');

bailOnErrors();


// Start

var config = loadConfig();
var app = createApp();
app.get('/', showLanding);
app.listen(config.http_port);
console.log('app: listening on ' + config.http_port);


// Details

function loadConfig() {
  var privates, defaults = require('./config-default.json');
  try { privates = require('./config-private.json'); } catch (e) {}
  return _.extend({}, defaults, privates);
}

function bailOnErrors() {
  process.on('uncaughtException', function(err) {
    console.log('exiting process for uncaught exception:', err.stack || err);
    process.exit();
  });
}

function createApp() {
  var timeouts = timeout({ throwError: true, time: config.timeout });
  var stylusMiddleware = stylus.middleware({
    src: path.join(__dirname, 'views'),
    dest: path.join(__dirname, 'public'),
    debug: config.stylus_debug,
    compile: compileStylus,
    force: config.stylus_force
  });
  var staticFiles = express['static'](path.join(__dirname, 'public'));

  var app = express();
  app.set('view engine', 'jade');
  app.set('view cache', config.view_cache);
  app.set('views', path.join(__dirname, 'views'));
  app.use(timeouts);
  app.use(express.limit(config.size_limit));
  app.use(express.compress());
  app.use(stylusMiddleware);
  app.use(staticFiles);
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(errorHandler);
  return app;

  function compileStylus(str, path) {
    return stylus(str)
      .set('compress', true)
      .set('filename', path);
  }

  function errorHandler(err, req, res, next) {
    console.log('error handler:', err.stack || err);
    return res.send('something went wrong');
  }
}

function showLanding(req, res, next) {
  res.render('landing');
}