(function() {
  var ControlState, Player, PositionState, constants, util;
  ControlState = require("controlstate");
  PositionState = require("positionstate");
  constants = require("constants");
  util = require('util');
  module.exports = Player = (function() {
    function Player(opts) {
      this.id = opts.id;
      this.breathing = false;
      this.max_x = opts.max_x;
      this.max_y = opts.max_y;
      this.trail = [];
      this.update(opts);
    }
    Player.prototype.serialized = function() {
      var data;
      return data = {
        controls: this.controls,
        position: this.position,
        speed: this.speed,
        energy: this.energy,
        id: this.id,
        name: this.name,
        damage: this.damage
      };
    };
    Player.prototype.update = function(opts) {
      this.controls = opts.controls || new ControlState(opts);
      this.position = opts.position || new PositionState(opts);
      this.speed = opts.speed || 0;
      this.energy = opts.energy || constants.maxEnergy;
      this.name = opts.name || "unknown";
      return this.damage = opts.damage || 0;
    };
    Player.prototype.handleInput = function() {
      if (this.controls.wPressed && this.speed < constants.maxSpeed) {
        this.speed += constants.accelRate;
      } else if (this.speed > constants.coastSpeed) {
        this.speed -= constants.decelRate;
      }
      if (this.controls.aPressed && !this.controls.dPressed) {
        this.position.angle += constants.playerTurnRate;
      } else if (this.controls.dPressed && !this.controls.aPressed) {
        this.position.angle -= constants.playerTurnRate;
      }
      if (this.position.angle > Math.PI * 2.0) {
        this.position.angle -= Math.PI * 2.0;
      }
      if (this.position.angle < 0.0) {
        return this.position.angle += Math.PI * 2.0;
      }
    };
    Player.prototype.thrusting = function() {
      return this.controls.wPressed && this.energy >= 1;
    };
    Player.prototype.gameTick = function() {
      this.breathing = false;
      this.handleInput();
      this.updatePosition();
      this.updateTrail();
      if (this.thrusting()) {
        return this.energy--;
      } else {
        this.energy += constants.energyRegenRate;
        return this.energy = Math.min(this.energy, constants.maxEnergy);
      }
    };
    Player.prototype.updatePosition = function() {
      var scale_x, scale_y, velocity_x, velocity_y;
      scale_y = Math.cos(this.position.angle);
      scale_x = Math.sin(this.position.angle);
      velocity_x = this.speed * scale_x;
      velocity_y = this.speed * scale_y;
      this.position.x -= velocity_x;
      return this.position.y -= velocity_y;
    };
    Player.prototype.updateTrail = function() {
      this.trail.unshift(this.thrusting() ? [this.position.x, this.position.y] : null);
      if (this.trail.length > constants.maxTrailLength) {
        return this.trail.pop();
      }
    };
    Player.prototype.tryToBreath = function(target) {
      var angleToPlayer, vecToPlayer;
      if (target.id === this.id) {
        return;
      }
      if (util.distSquared(this.position, target.position) < constants.fireDistanceSquared) {
        vecToPlayer = util.subtractVec(target.position, this.position);
        angleToPlayer = Math.PI + Math.atan2(vecToPlayer.x, vecToPlayer.y);
        if (Math.abs(angleToPlayer - this.position.angle) < 0.8) {
          this.breathing = angleToPlayer;
          return target.damage++;
        }
      }
    };
    Player.prototype.drawTrail = function(context) {
      var coord, opacity, x, y, _i, _len, _ref, _results;
      opacity = 0.3;
      _ref = this.trail;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        coord = _ref[_i];
        opacity -= 0.01;
        _results.push(coord ? ((x = coord[0], y = coord[1], coord), context.fillStyle = "rgba(255,255,255," + opacity + ")", context.fillRect(x, y, 8, 8)) : void 0);
      }
      return _results;
    };
    Player.prototype.drawShip = function(context) {
      context.fillStyle = "#fff";
      context.fillRect(0, 0, 8, 8);
      context.fillStyle = this.thrusting() ? "red" : "rgba(255,255,255,0.5)";
      return context.fillRect(0, 8, 8, 2);
    };
    Player.prototype.drawFire = function(context) {
      context.fillStyle = "red";
      context.beginPath();
      context.moveTo(4, 8);
      context.lineTo(12, -40);
      context.lineTo(-4, -40);
      return context.fill();
    };
    Player.prototype.draw = function(context) {
      context.save();
      this.drawTrail(context);
      context.translate(this.position.x, this.position.y);
      context.fillStyle = "#fff";
      context.fillText(this.name, -4, -15);
      context.rotate(-this.position.angle);
      context.translate(-4, -3);
      if (this.breathing) {
        this.drawFire(context);
      }
      this.drawShip(context);
      return context.restore();
    };
    return Player;
  })();
}).call(this);
