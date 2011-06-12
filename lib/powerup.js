(function() {
  var Animation, Powerup, constants, util;
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
  module.exports = Powerup = (function() {
    __extends(Powerup, Animation);
    function Powerup() {
      Powerup.__super__.constructor.apply(this, arguments);
    }
    Powerup.prototype.prepare_animation = function(opts) {
      this.radius = 10;
      return this.color = "#ffff00";
    };
    Powerup.prototype.draw = function(context) {
      context.fillStyle = this.color;
      context.beginPath();
      context.arc(this.x, this.y, 5, 0, Math.PI * 2, true);
      context.closePath();
      context.stroke();
      return context.fill();
    };
    Powerup.prototype.apply_bonus = function(player) {
      return player.energy = constants.maxEnergy;
    };
    Powerup.prototype.contains = function(position) {
      var dist;
      dist = util.distanceFrom({
        x: this.x,
        y: this.y
      }, position);
      return dist < this.radius;
    };
    return Powerup;
  })();
}).call(this);
