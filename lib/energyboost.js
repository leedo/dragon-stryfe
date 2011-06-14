(function() {
  var EnergyBoost, Powerup, constants;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  Powerup = require("powerup").Powerup;
  constants = require("constants");
  module.exports = EnergyBoost = (function() {
    __extends(EnergyBoost, Powerup);
    function EnergyBoost() {
      EnergyBoost.__super__.constructor.apply(this, arguments);
    }
    EnergyBoost.prototype.prepare_powerup = function(opts) {
      this.img = document.getElementById("energy-powerup");
      return this.radius = 10;
    };
    EnergyBoost.prototype.draw = function(context) {
      var orig;
      context.save();
      console.log(this.x, this.y);
      context.translate(this.x + 5, this.y + 5);
      context.rotate(-45);
      orig = context.globalCompositeOperation;
      context.globalCompositeOperation = "destination-over";
      context.drawImage(this.img, 0, 0);
      context.globalCompositeOperation = orig;
      return context.restore();
    };
    EnergyBoost.prototype.apply_bonus = function(player) {
      return player.energy_regen += constants.maxEnergy / 2;
    };
    return EnergyBoost;
  })();
}).call(this);
