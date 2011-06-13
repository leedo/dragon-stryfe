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
      this.radius = 10;
      return this.color = "#ffff00";
    };
    EnergyBoost.prototype.apply_bonus = function(player) {
      player.energy += constants.maxEnergy / 4;
      return player.energy = Math.max(constants.maxEnergy, player.energy);
    };
    return EnergyBoost;
  })();
}).call(this);
