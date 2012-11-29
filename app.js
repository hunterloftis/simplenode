var express = require('express');
var timeout = require('connect-timeout');
var stylus = require('stylus');
var nib = require('nib');
var path = require('path');

// Config
var STYLUS_FORCE = true;
var STYLUS_DEBUG = true;
var PORT = 3000;

// Start
var app = createApp();
app.get('/', hello);
app.listen(PORT);
console.log('app: listening on ' + PORT);


// Details

function createApp() {
  var timeouts = timeout({ throwError: true, time: 10000 });
  var stylusMiddleware = stylus.middleware({
    src: __dirname,
    dest: __dirname,
    debug: STYLUS_DEBUG,
    compile: compileStylus,
    force: STYLUS_FORCE
  });

  var app = express();
  app.use(timeouts);
  app.use(express.compress());
  app.use(stylusMiddleware);
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  return app;

  function compileStylus(str, path) {
    return stylus(str)
      .set('compress', true)
      .set('filename', path)
      .use(nib());
  }
}

function hello(req, res, next) {
  res.send('Hello, world!');
}
