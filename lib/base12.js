var fs = require('fs');
var _ = require('underscore');
var util = require('util');
var events = require('events');
var cluster = require('cluster');
var os = require('os');

// Base12

function Base12() {
  this._main = undefined;
  this._restart = true;
  this._bail = true;
  this._workers = os.cpus().length;
  this._config = {};
}

util.inherits(Base12, events.EventEmitter);

Base12.prototype.bail = accessor('_bail');
Base12.prototype.main = accessor('_main');
Base12.prototype.restart = accessor('_restart');
Base12.prototype.workers = accessor('_workers');

Base12.prototype.config = function() {
  if (arguments.length === 0) return this._config;
  this._config = this._loadConfig.apply(this, arguments);
  return this;
};

Base12.prototype.start = function() {
  if (this._bail) this._bailOnError();
  this._balanceCluster();
};

Base12.prototype._bailOnError = function(fn) {
  process.on('uncaughtException', onException);
  function onException(err) {
    var exit = fn ? fn(err) : true;
    this.emit('bail', err);
    console.error('base12 bail:', err.stack || err);
    if (exit) process.exit();
  }
};

Base12.prototype._balanceCluster = function() {
  var self = this;

  return cluster.isMaster? startMaster() : this._main(_.clone(this._config));

  function startMaster() {
    var workerCount = self._workers;

    if (self._restart) {
      cluster.on('exit', onWorkerExit);
      cluster.on('death', onWorkerDeath);
    }

    while(workerCount--) cluster.fork();
  }

  function onWorkerExit(worker) {
    console.log('base12 balance - worker exit, forking replacement');
    cluster.fork();
  }

  function onWorkerDeath(worker) {
    console.error('base12 balance - worker death, forking replacement');
    cluster.fork();
  }
};

Base12.prototype._loadConfig = function() {
  var config = {};
  var args = Array.prototype.slice.call(arguments);
  args.forEach(loadFile);

  function loadFile(file) {
    try {
      var data = fs.readFileSync(file, 'utf8');
      _.extend(config, JSON.parse(data));
    } catch (e) {
      if (e.code === 'ENOENT') return console.log('base12 config - file not found, skipping:', file);
      console.error('base12 config:', e.stack || e);
    }
  }
  this.emit('config', config);
  return config;
};

// Exports

module.exports = new Base12();

// Utils

function accessor(key) {
  return function(val) {
    if (arguments.length === 0) return this[key];
    this[key] = val;
    return this;
  };
}