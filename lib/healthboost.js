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
      this.img = document.getElementById("health-powerup");
      this.radius = 10;
      return this.rgb = [66, 133, 65];
    };
    HealthBoost.prototype.apply_bonus = function(player) {
      return player.health_regen += constants.deadlyDamage / 2;
    };
    return HealthBoost;
  })();
}).call(this);
