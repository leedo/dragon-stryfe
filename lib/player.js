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
      this.img = document.getElementById("dragon");
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
      this.damage = opts.damage || 0;
      this.dead = opts.dead || 0;
      return this.flash = opts.flash || 0;
    };
    Player.prototype.handleInput = function() {
      var angleToTarget, distAway, sign, toTarget, turnAmount;
      if (this.dead !== 0) {
        this.speed = 0;
        this.position.angle = Math.PI * this.dead / 10.0;
        this.dead++;
        return;
      }
      if (this.controls.spacePressed) {
        this.breathing = Math.PI;
      }
      if (this.controls.wPressed && this.speed < constants.maxSpeed) {
        this.speed += constants.accelRate;
      }
      if (this.controls.sPressed && this.speed > constants.minSpeed) {
        this.speed -= constants.brakingRate;
        if (this.speed < constants.minSpeed) {
          this.speed = 0;
        }
      }
      if (this.controls.target !== false) {
        toTarget = util.subtractVec(this.controls.target, this.position);
        angleToTarget = Math.PI + Math.atan2(toTarget.x, toTarget.y) - this.position.angle;
        if (angleToTarget > Math.PI) {
          sign = -1;
        } else if (angleToTarget > 0) {
          sign = 1;
        } else if (angleToTarget > -Math.PI) {
          sign = 1;
        } else {
          sign = -1;
        }
        turnAmount = util.clamp(angleToTarget * sign, -constants.playerTurnRate, constants.playerTurnRate);
        this.position.angle += turnAmount;
        this.speed = Math.min(constants.maxSpeed, constants.accelRate + this.speed);
        distAway = util.length(toTarget);
        if (distAway < 10.0) {
          this.controls.target = false;
        }
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
    Player.prototype.updateEnergy = function() {
      if (this.thrusting()) {
        return this.energy--;
      } else {
        this.energy += constants.energyRegenRate;
        return this.energy = Math.min(this.energy, constants.maxEnergy);
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
      return this.updateEnergy();
    };
    Player.prototype.updatePosition = function() {
      var scale_x, scale_y, velocity_x, velocity_y;
      scale_y = Math.cos(this.position.angle);
      scale_x = Math.sin(this.position.angle);
      velocity_x = this.speed * scale_x;
      velocity_y = this.speed * scale_y;
      this.position.x -= velocity_x;
      this.position.x = Math.min(constants.universeWidth, Math.max(this.position.x, 0));
      this.position.y -= velocity_y;
      return this.position.y = Math.min(constants.universeHeight, Math.max(this.position.y, 0));
    };
    Player.prototype.updateTrail = function() {
      var dist;
      dist = this.trail.length ? util.distanceFrom(this.position, this.trail[0]) : 0;
      if (!this.trail.length || dist > 4) {
        this.trail.unshift({
          x: this.position.x,
          y: this.position.y,
          dist: dist,
          angle: this.position.angle
        });
        if (this.trail.length > constants.maxTrailLength) {
          return this.trail.pop();
        }
      }
    };
    Player.prototype.tryToBreath = function(target) {
      var angleToPlayer, vecToPlayer;
      if (target.id === this.id || this.dead) {
        return;
      }
      if (util.distSquared(this.position, target.position) < constants.fireDistanceSquared) {
        vecToPlayer = util.subtractVec(target.position, this.position);
        angleToPlayer = Math.PI + Math.atan2(vecToPlayer.x, vecToPlayer.y);
        if (Math.abs(angleToPlayer - this.position.angle) < 0.8) {
          this.breathing = angleToPlayer;
          return target.damage += Math.max(this.speed, 0);
        }
      }
    };
    Player.prototype.drawTail = function(context) {
      var coord, prev, width, _i, _len, _ref, _results;
      context.fillStyle = "#fff";
      width = 3;
      _ref = this.trail;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        coord = _ref[_i];
        if (coord && prev) {
          context.save();
          context.translate(coord.x, coord.y);
          context.rotate(-coord.angle);
          context.fillRect(0, 0, width, coord.dist + 2);
          context.restore();
          width -= 0.2;
        }
        _results.push(prev = coord);
      }
      return _results;
    };
    Player.prototype.drawShip = function(context) {
      return context.drawImage(this.img, -10, 0);
    };
    Player.prototype.drawFire = function(context) {
      var block, blocks, blocksize, dist, opacity, rate, transparency, width, x, y;
      width = 8;
      blocksize = 8;
      rate = 1.8;
      transparency = 0.1;
      context.save();
      context.translate(0, -10);
      for (dist = 0; dist <= 4; dist++) {
        blocks = Math.ceil(width / blocksize);
        x = -(width / 2);
        y = -(blocksize * dist);
        transparency += 0.15;
        for (block = 0; 0 <= blocks ? block <= blocks : block >= blocks; 0 <= blocks ? block++ : block--) {
          opacity = (parseInt(Math.random() * 10) / 10) - transparency;
          context.fillStyle = "rgba(255,127,0," + opacity + ")";
          context.fillRect(x + (block * blocksize), y, blocksize + 1, blocksize + 1);
        }
        width = width * rate;
      }
      return context.restore();
    };
    Player.prototype.drawName = function(context) {
      context.save();
      context.translate(this.position.x, this.position.y);
      context.fillStyle = "#000";
      context.fillText(this.name, -5, -15);
      context.fillText(this.name, -3, -17);
      context.fillStyle = "#fff";
      context.fillText(this.name, -4, -16);
      return context.restore();
    };
    Player.prototype.draw = function(context) {
      var oldfillstyle;
      this.drawTail(context);
      context.save();
      context.translate(this.position.x, this.position.y);
      context.rotate(-this.position.angle);
      context.translate(-4, -3);
      if (this.flash > 4) {
        oldfillstyle = this.context.fillstyle;
        this.context.fillstyle = "#ff0";
        this.context.arc(this.position.x, this.position.y, 30, 0, 2 * Math.PI, false);
        this.context.fill();
        this.context.fillstyle = oldfillstyle;
        this.flash++;
      } else if (this.flash >= 4) {
        this.flash = 0;
      }
      this.drawShip(context);
      if (this.breathing) {
        this.drawFire(context);
      }
      context.restore();
      return this.drawName(context);
    };
    return Player;
  })();
}).call(this);
