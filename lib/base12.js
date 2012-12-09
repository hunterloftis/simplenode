var fs = require('fs');
var _ = require('underscore');
var util = require('util');
var events = require('events');
var cluster = require('cluster');
var os = require('os');

function Base12() {

}

util.inherits(Base12, events.EventEmitter);

Base12.prototype.bail = function bailOnError(fn) {
  process.on('uncaughtException', onException);
  function onException(err) {
    var exit = fn ? fn(err) : true;
    this.emit('bail', err);
    console.error('base12 bail:', err.stack || err);
    if (exit) process.exit();
  }
};

Base12.prototype.balance = function balanceCluster(startWorker, options) {
  var max = options.max || os.cpus().length;
  var restart = (typeof options.restart === 'undefined') ? true : options.restart;

  return cluster.isMaster? startMaster() : startWorker();

  function startMaster() {
    var workerCount = max;

    if (restart) {
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

Base12.prototype.config = function loadConfig() {
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

module.exports = new Base12();