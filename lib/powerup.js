(function() {
  var Powerup, constants, util;
  util = require("util");
  constants = require("constants");
  module.exports = Powerup = (function() {
    function Powerup(x, y) {
      this.x = x;
      this.y = y;
      this.radius = 10;
      this.color = "#ffff00";
    }
    Powerup.prototype.draw = function(context) {
      var orig;
      orig = context.globalCompositeOperation;
      context.globalCompositeOperation = "destination-over";
      context.fillStyle = this.color;
      context.beginPath();
      context.arc(this.x, this.y, 5, 0, Math.PI * 2, true);
      context.closePath();
      context.stroke();
      context.fill();
      return context.globalCompositeOperation = orig;
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
