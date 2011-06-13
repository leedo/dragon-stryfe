(function() {
  var Animation, Powerup, constants, types, util;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  Animation = require("animation");
  util = require("util");
  constants = require("constants");
  exports.Powerup = Powerup = (function() {
    __extends(Powerup, Animation);
    function Powerup() {
      Powerup.__super__.constructor.apply(this, arguments);
    }
    Powerup.prototype.prepare_animation = function(opts) {
      this.radius = 10;
      this.rgb = [255, 255, 255];
      return this.prepare_powerup(opts);
    };
    Powerup.prototype.draw = function(context) {
      var orig;
      orig = context.globalCompositeOperation;
      context.globalCompositeOperation = "destination-over";
      context.drawImage(this.img, this.x, this.y);
      return context.globalCompositeOperation = orig;
    };
    Powerup.prototype.contains = function(position) {
      var dist;
      dist = util.distanceFrom({
        x: this.x + this.radius / 2,
        y: this.y + this.radius / 2
      }, position);
      return dist < this.radius;
    };
    return Powerup;
  })();
  types = {
    health: require("healthboost"),
    energy: require("energyboost")
  };
  exports.createPowerup = function(type, opts) {
    return new types[type](opts);
  };
}).call(this);
