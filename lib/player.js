(function() {
  var Player, Self, accelRate, coastSpeed, decelRate, maxSpeed, maxThrust, maxTrailLength, playerTurnRate, thrustRegenRate;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  exports.createPlayer = function(opts) {
    return new Player(opts);
  };
  exports.createSelf = function(opts) {
    return new Self(opts);
  };
  playerTurnRate = 0.05;
  maxThrust = 100.0;
  thrustRegenRate = 0.25;
  maxTrailLength = 15;
  maxSpeed = 8;
  accelRate = 0.4;
  coastSpeed = 0.4;
  decelRate = 0.1;
  Player = (function() {
    function Player(opts) {
      this.sync = ["name", "speed", "angle", "x", "y", "trail", "thrusting"];
      this.x = opts.x || 0;
      this.y = opts.y || 0;
      this.speed = opts.speed || 0;
      this.angle = opts.angle || 0;
      this.id = opts.id;
      this.thrusting = opts.thrusting || false;
      this.name = opts.name || "unknown";
      this.trail = [];
      this.controls = opts.controls || {
        wPressed: false,
        aPressed: false,
        dPressed: false
      };
    }
    Player.prototype.serialized = function() {
      var data, field, _i, _len, _ref;
      data = {};
      _ref = this.sync;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        data[field] = this[field];
      }
      return data;
    };
    Player.prototype.gameTick = function() {
      var scale_x, scale_y, velocity_x, velocity_y;
      scale_y = Math.cos(this.angle);
      scale_x = Math.sin(this.angle);
      velocity_x = this.speed * scale_x;
      velocity_y = this.speed * scale_y;
      this.x -= velocity_x;
      return this.y -= velocity_y;
    };
    Player.prototype.updateTrail = function() {
      this.trail.unshift(this.thrusting ? [this.x, this.y] : null);
      if (this.trail.length > maxTrailLength) {
        return this.trail.pop();
      }
    };
    return Player;
  })();
  Self = (function() {
    __extends(Self, Player);
    function Self() {
      this.turn = 0;
      this.thrusting = false;
      this.thrust = maxThrust;
      Self.__super__.constructor.apply(this, arguments);
    }
    Self.prototype.handleInput = function() {
      if (this.controls.aPressed === true && this.controls.dPressed === false) {
        this.angle += playerTurnRate;
      } else if (this.controls.dPressed === true && this.controls.aPressed === false) {
        this.angle -= playerTurnRate;
      }
      if (this.thrusting && this.speed < maxSpeed) {
        return this.speed += accelRate;
      } else if (this.speed > coastSpeed) {
        return this.speed -= decelRate;
      }
    };
    Self.prototype.gameTick = function() {
      this.handleInput();
      Self.__super__.gameTick.apply(this, arguments);
      if (this.thrusting && this.thrust >= 1) {
        return this.thrust--;
      } else {
        this.thrust += thrustRegenRate;
        this.thrust = Math.min(this.thrust, maxThrust);
        return this.thrusting = false;
      }
    };
    return Self;
  })();
}).call(this);
