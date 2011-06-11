(function() {
  var ControlState, Player, PositionState, breath, constants, screech, util;
  ControlState = require("controlstate");
  PositionState = require("positionstate");
  constants = require("constants");
  util = require('util');
  breath = new Audio('breath.m4a');
  screech = new Audio('screech.m4a');
  module.exports = Player = (function() {
    function Player(opts) {
      this.id = opts.id;
      this.breathing = false;
      this.img = document.getElementById("dragon");
      this.trail = [];
      this.update(opts);
      if (opts.colors && opts.colors.length) {
        this.body_color = opts.colors[4];
        this.highlight_color = opts.colors[2];
      } else {
        this.body_color = util.randomColor();
        this.highlight_color = util.randomColor();
      }
    }
    Player.prototype.serialized = function() {
      var data;
      return data = {
        body_color: this.body_color,
        highlight_color: this.highlight_color,
        controls: this.controls,
        position: this.position,
        speed: this.speed,
        energy: this.energy,
        id: this.id,
        name: this.name,
        damage: this.damage,
        dead: this.dead
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
      this.flash = opts.flash || 0;
      this.body_color = opts.body_color || this.body_color;
      return this.highlight_color = opts.highlight_color || this.highlight_color;
    };
    Player.prototype.deathTick = function() {
      if (this.dead === 1) {
        screech.play();
      }
      this.position.angle = Math.PI * this.dead / 10.0;
      this.speed = Math.max(this.speed - 0.5, 0);
      return this.dead++;
    };
    Player.prototype.handleInput = function() {
      var angleToTarget, distAway, multiplier, sign, toTarget, turnAmount, turnLimit;
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
        turnLimit = this.speed * constants.playerTurnRate;
        if (this.thrusting()) {
          turnLimit *= 4;
        }
        turnAmount = util.clamp(angleToTarget / sign, -turnLimit, turnLimit);
        this.position.angle += turnAmount;
        this.speed = Math.min(constants.maxSpeed, constants.accelRate + this.speed);
        distAway = util.length(toTarget);
        if (distAway < 10.0) {
          this.controls.target = false;
        }
      } else if (this.speed > constants.coastSpeed) {
        this.speed -= constants.decelRate;
      }
      multiplier = 0;
      if (this.controls.aPressed && !this.controls.dPressed) {
        multiplier = this.thrusting() || this.controls.sPressed ? 4 : 1;
      } else if (this.controls.dPressed && !this.controls.aPressed) {
        multiplier = this.thrusting() || this.controls.sPressed ? -4 : -1;
      }
      this.position.angle += constants.playerTurnRate * this.speed * multiplier;
      if (this.position.angle > Math.PI * 2.0) {
        this.position.angle -= Math.PI * 2.0;
      }
      if (this.position.angle < 0.0) {
        return this.position.angle += Math.PI * 2.0;
      }
    };
    Player.prototype.updateEnergy = function() {
      if (this.dead) {
        return this.energy = 0;
      } else if (this.thrusting()) {
        this.energy--;
        if (!this.energy) {
          return this.controls.wPressed = false;
        }
      } else {
        this.energy += constants.energyRegenRate;
        return this.energy = Math.min(this.energy, constants.maxEnergy);
      }
    };
    Player.prototype.thrusting = function() {
      return (this.controls.wPressed || this.controls.target) && this.energy >= 1;
    };
    Player.prototype.gameTick = function() {
      this.breathing = false;
      if (this.dead > 0) {
        this.deathTick();
      } else {
        this.handleInput();
      }
      this.updateEnergy();
      this.updateTrail();
      return this.updatePosition();
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
      if (this.dead) {
        this.trail = [];
        return;
      }
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
          target.damage += Math.max(this.speed, 0);
          return breath.play();
        }
      }
    };
    Player.prototype.drawTail = function(context) {
      var coord, i, prev, width, _ref, _results;
      width = 3;
      _ref = this.trail;
      _results = [];
      for (i in _ref) {
        coord = _ref[i];
        if (coord && prev) {
          context.save();
          context.fillStyle = i % 2 ? this.body_color : this.highlight_color;
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
      var orig;
      context.drawImage(this.img, -10, 0);
      orig = context.globalCompositeOperation;
      context.globalCompositeOperation = "source-atop";
      context.fillStyle = this.body_color;
      context.fillRect(1, 0, 10, 30);
      context.fillRect(1, 1, 10, 10);
      context.fillStyle = this.highlight_color;
      context.fillRect(-10, 10, 12, 16);
      context.fillRect(10, 10, 12, 16);
      return context.globalCompositeOperation = orig;
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
    Player.prototype.drawName = function(context, health) {
      var percent;
      context.save();
      context.translate(this.position.x - 4, this.position.y - 16);
      if (health) {
        context.fillStyle = "#000";
        context.fillRect(-1, 2, 22, 4);
        percent = this.damage / constants.deadlyDamage;
        context.fillStyle = percent < .8 ? "green" : "red";
        context.fillRect(0, 3, 20 - 20 * percent, 2);
      }
      util.drawOutlinedText(context, this.name, 0, 0);
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
      return context.restore();
    };
    return Player;
  })();
}).call(this);
