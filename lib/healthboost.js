(function() {
  var HealthBoost, Powerup, constants;
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
  module.exports = HealthBoost = (function() {
    __extends(HealthBoost, Powerup);
    function HealthBoost() {
      HealthBoost.__super__.constructor.apply(this, arguments);
    }
    HealthBoost.prototype.prepare_powerup = function(opts) {
      this.radius = 8;
      return this.color = "green";
    };
    HealthBoost.prototype.apply_bonus = function(player) {
      player.damage -= constants.deadlyDamage / 4;
      return player.damage = Math.max(0, player.damage);
    };
    return HealthBoost;
  })();
}).call(this);
