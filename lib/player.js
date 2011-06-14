(function() {
  var Animation, ControlState, Player, breath, constants, screech, util;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  ControlState = require("controlstate");
  Animation = require("animation");
  constants = require("constants");
  util = require('util');
  breath = new Audio('breath.m4a');
  screech = new Audio('screech.m4a');
  module.exports = Player = (function() {
    __extends(Player, Animation);
    function Player() {
      Player.__super__.constructor.apply(this, arguments);
    }
    Player.prototype.prepare_animation = function(opts) {
      this.name = opts.name || "unknown";
      this.body_color = opts.body_color;
      this.highlight_color = opts.highlight_color;
      this.controls = new ControlState() || opts.controls;
      this.breathing = false;
      this.img = document.getElementById("dragon");
      this.trail = [];
      this.segment_dist = 0;
      this.energy = constants.maxEnergy;
      this.damage = 0;
      this.dead = 0;
      this.flash = 0;
      this.kills = 0;
      this.last_attacker = null;
      this.health_regen = 0;
      return this.energy_regen = 0;
    };
    Player.prototype.serialized = function(full) {
      var data, field, fields, _i, _len;
      fields = ["id", "controls", "energy", "x", "y", "angle", "speed", "damage", "dead", "kills"];
      data = {};
      if (full) {
        fields = fields.concat(["name", "body_color", "highlight_color"]);
      }
      for (_i = 0, _len = fields.length; _i < _len; _i++) {
        field = fields[_i];
        data[field] = this[field];
      }
      return data;
    };
    Player.prototype.deathTick = function() {
      if (this.dead === 1) {
        screech.play();
      }
      this.angle = Math.PI * this.dead / 10.0;
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
          this.speed = constants.minSpeed;
        }
      }
      if (this.controls.target !== false) {
        toTarget = util.subtractVec(this.controls.target, this);
        angleToTarget = Math.PI + Math.atan2(toTarget.x, toTarget.y) - this.angle;
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
        this.angle += turnAmount;
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
      this.angle += constants.playerTurnRate * this.speed * multiplier;
      if (this.angle > Math.PI * 2.0) {
        this.angle -= Math.PI * 2.0;
      }
      if (this.angle < 0.0) {
        return this.angle += Math.PI * 2.0;
      }
    };
    Player.prototype.updateStats = function() {
      if (this.dead) {
        this.energy = 0;
      } else if (this.thrusting()) {
        this.energy--;
        if (!this.energy) {
          this.controls.wPressed = false;
        }
      } else {
        this.energy += constants.energyRegenRate;
      }
      if (this.health_regen > 0) {
        this.health_regen--;
        this.damage--;
      }
      if (this.energy_regen > 0) {
        this.energy_regen -= 2;
        this.energy += 2;
      }
      this.damage = Math.max(this.damage, 0);
      return this.energy = Math.min(this.energy, constants.maxEnergy);
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
      this.updateStats();
      this.updateTrail();
      return this.updatePosition();
    };
    Player.prototype.updatePosition = function() {
      var scale_x, scale_y, velocity_x, velocity_y;
      scale_y = Math.cos(this.angle);
      scale_x = Math.sin(this.angle);
      velocity_x = this.speed * scale_x;
      velocity_y = this.speed * scale_y;
      this.x -= velocity_x;
      this.y -= velocity_y;
      this.x = util.clamp(this.x, 0, constants.universeWidth);
      return this.y = util.clamp(this.y, 0, constants.universeHeight);
    };
    Player.prototype.updateTrail = function() {
      var dist;
      if (this.dead) {
        this.trail = [];
        return;
      }
      this.segment_dist += this.speed;
      dist = Math.abs(this.segment_dist);
      if (dist > 3) {
        this.trail.unshift({
          x: this.x,
          y: this.y,
          dist: dist,
          angle: this.angle
        });
        if (this.trail.length > constants.maxTrailLength) {
          this.trail.pop();
        }
        return this.segment_dist = 0;
      }
    };
    Player.prototype.tryToBreath = function(target) {
      var angleToPlayer, vecToPlayer;
      if (target.id === this.id || this.dead) {
        return;
      }
      if (util.distSquared(this, target) < constants.fireDistanceSquared) {
        vecToPlayer = util.subtractVec(target, this);
        angleToPlayer = Math.PI + Math.atan2(vecToPlayer.x, vecToPlayer.y);
        if (Math.abs(angleToPlayer - this.angle) < 0.8) {
          this.breathing = angleToPlayer;
          target.damage += Math.max(this.speed, 0);
          target.last_attacker = this.id;
          return breath.play();
        }
      }
    };
    Player.prototype.drawTail = function(context) {
      var i, segment, width, _ref, _results;
      width = 3;
      _ref = this.trail.slice(0, 9);
      _results = [];
      for (i in _ref) {
        segment = _ref[i];
        context.save();
        context.fillStyle = i % 2 ? this.body_color : this.highlight_color;
        context.translate(segment.x, segment.y);
        context.rotate(-segment.angle);
        context.fillRect(0, 0, width, segment.dist + 2);
        width -= 0.2;
        _results.push(context.restore());
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
          context.fillStyle = "rgba(255,255,255," + opacity + ")";
          context.fillRect(x + (block * blocksize), y, blocksize + 1, blocksize + 1);
        }
        width = width * rate;
      }
      return context.restore();
    };
    Player.prototype.hp = function() {
      return util.clamp(constants.deadlyDamage - this.damage, 0, constants.deadlyDamage);
    };
    Player.prototype.hpPercent = function() {
      return this.hp() / constants.deadlyDamage;
    };
    Player.prototype.drawName = function(context, health) {
      var percent;
      context.save();
      context.translate(this.x - 4, this.y - 16);
      if (health) {
        context.fillStyle = "#000";
        context.fillRect(-1, 2, 22, 4);
        percent = this.hpPercent();
        context.fillStyle = percent > .2 ? "green" : "red";
        context.fillRect(0, 3, percent * 20, 2);
      }
      context.font = "bold 10px sans-serif";
      util.drawOutlinedText(context, this.name, 0, 0);
      return context.restore();
    };
    Player.prototype.draw = function(context) {
      var oldfillstyle;
      this.drawTail(context);
      context.save();
      context.translate(this.x, this.y);
      context.rotate(-this.angle);
      context.translate(-4, -3);
      if (this.flash > 4) {
        oldfillstyle = this.context.fillstyle;
        this.context.fillstyle = "#ff0";
        this.context.arc(this.x, this.y, 30, 0, 2 * Math.PI, false);
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
