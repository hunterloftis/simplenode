var express = require('express');
var timeout = require('connect-timeout');
var stylus = require('stylus');
var path = require('path');

var b12 = require('./lib/base12');

// Start

if (module === require.main) {
  b12.bail();
  b12.balance(startApp, {
    restart: false
  });
}

function startApp() {
  var config = b12.config('config-default.json', 'config-private.json');
  var app = createApp(config);
  app.get('/', showLanding);
  app.listen(config.http_port);

  console.log('app: listening on ' + config.http_port);
}

// Details

function createApp(config) {
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
  app
    .set('view engine', 'jade')
    .set('view cache', config.view_cache)
    .set('views', path.join(__dirname, 'views'))
    .use(timeouts)
    .use(express.limit(config.size_limit))
    .use(express.compress())
    .use(stylusMiddleware)
    .use(staticFiles)
    .use(express.bodyParser())
    .use(express.methodOverride())
    .use(app.router)
    .use(notFound)
    .use(errorHandler);

  return app;

  function compileStylus(str, path) {
    return stylus(str)
      .set('compress', true)
      .set('filename', path);
  }

  function errorHandler(err, req, res, next) {
    console.log('error handler:', err.stack || err);
    return res.send(500, 'Sorry, something went wrong.');
  }
}

function showLanding(req, res, next) {
  res.render('landing');
}

function notFound(req, res, next) {
  res.send(404, 'Nothing here.');
}