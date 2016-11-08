// original: https://github.com/CoderPuppy/os-browserify
var {
  DeviceEventEmitter,
  NativeModules
} = require('react-native');
var RNOS = NativeModules.RNOS;

// update the osInfo
var osInfo = { }
DeviceEventEmitter.addListener('rn-os-info', function (info) {
    osInfo = info;
});

exports.endianness = function () { return 'LE' };

exports.hostname = function () {
    if (typeof location !== 'undefined') {
        return location.hostname
    }
    else return '';
};

exports.loadavg = function () { return [] };

exports.uptime = function () { return 0 };

exports.freemem = function () {
    return Number.MAX_VALUE;
};

exports.totalmem = function () {
    return Number.MAX_VALUE;
};

exports.cpus = function () { return [] };

exports.type = function () { return 'Browser' };

exports.release = function () {
    if (typeof navigator !== 'undefined') {
        return navigator.appVersion;
    }
    return '';
};

exports.networkInterfaces
= exports.getNetworkInterfaces
= function () {
    return osInfo.networkInterfaces || RNOS.networkInterfaces
};

exports.arch = function () { return 'javascript' };

exports.platform = function () { return 'browser' };

exports.tmpdir = exports.tmpDir = function () {
    return '/tmp';
};

exports.EOL = '\n';