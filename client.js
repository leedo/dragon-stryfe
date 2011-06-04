(function() {
  var Player, Self, Universe;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Player = (function() {
    function Player(opts) {
      this.x = opts.x || 0;
      this.y = opts.y || 0;
      this.speed = opts.speed || 0;
      this.angle = opts.angle || 0;
      this.id = opts.id;
    }
    Player.prototype.gameTick = function() {
      var scale_x, scale_y, velocity_x, velocity_y;
      scale_y = -Math.cos(this.angle);
      scale_x = Math.sin(this.angle);
      velocity_x = this.speed * scale_x;
      velocity_y = this.speed * scale_y;
      this.x -= velocity_x;
      return this.y -= velocity_y;
    };
    return Player;
  })();
  Self = (function() {
    __extends(Self, Player);
    function Self() {
      this.turn = 0;
      this.thrust = false;
      Self.__super__.constructor.apply(this, arguments);
    }
    Self.prototype.handleInput = function() {
      if (this.turn !== 0) {
        this.angle += this.turn * 0.05;
      }
      if (this.thrust && this.speed < 2) {
        return this.speed += 0.1;
      } else if (this.speed > 0.1) {
        return this.speed -= 0.025;
      }
    };
    Self.prototype.gameTick = function() {
      this.handleInput();
      return Self.__super__.gameTick.apply(this, arguments);
    };
    return Self;
  })();
  Universe = (function() {
    function Universe() {
      this.self;
      this.players = {};
      this.board = document.getElementById("universe");
      this.board.width = document.width;
      this.board.height = document.height;
      this.center = [this.board.width / 2, this.board.height / 2];
      this.context = this.board.getContext("2d");
      this.socket = this.connect();
      setInterval((__bind(function() {
        return this.gameTick();
      }, this)), 10);
    }
    Universe.prototype.coordToPos = function(x, y) {
      return [this.center[0] - x, this.center[1] - y];
    };
    Universe.prototype.posToCoord = function(x, y) {
      return [x - this.center[0], this.center[1] - y];
    };
    Universe.prototype.gameTick = function() {
      var id, player, _ref, _results;
      this.board.width = this.board.width;
      if (this.self) {
        this.tickPlayer(this.self);
      }
      _ref = this.players;
      _results = [];
      for (id in _ref) {
        player = _ref[id];
        _results.push(this.tickPlayer(player));
      }
      return _results;
    };
    Universe.prototype.syncSelf = function() {
      return this.socket.send({
        x: this.self.x,
        y: this.self.y,
        speed: this.self.speed,
        angle: this.self.angle
      });
    };
    Universe.prototype.tickPlayer = function(player) {
      player.gameTick();
      return this.drawPlayer(player);
    };
    Universe.prototype.initSelf = function(state) {
      console.log("init self with id " + state.id);
      this.self = new Self(state);
      this.drawPlayer(this.self);
      this.enableControls();
      return setInterval((__bind(function() {
        return this.syncSelf();
      }, this)), 100);
    };
    Universe.prototype.enableControls = function() {
      document.addEventListener("keyup", __bind(function(e) {
        switch (e.keyCode) {
          case 87:
            return this.self.thrust = false;
          case 68:
            return this.self.turn = 0;
          case 65:
            return this.self.turn = 0;
        }
      }, this));
      return document.addEventListener("keydown", __bind(function(e) {
        switch (e.keyCode) {
          case 87:
            return this.self.thrust = true;
          case 68:
            return this.self.turn = 1;
          case 65:
            return this.self.turn = -1;
        }
      }, this));
    };
    Universe.prototype.removePlayer = function(id) {
      console.log("remove player " + id);
      return delete this.players[id];
    };
    Universe.prototype.addPlayer = function(state) {
      var player;
      console.log("add player " + state.id);
      player = new Player(state);
      this.drawPlayer(player);
      return this.players[player.id] = player;
    };
    Universe.prototype.addPlayers = function(new_players) {
      var player, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = new_players.length; _i < _len; _i++) {
        player = new_players[_i];
        _results.push(this.addPlayer(player));
      }
      return _results;
    };
    Universe.prototype.syncPlayer = function(state) {
      var player;
      player = this.players[state.id];
      if (!player) {
        return;
      }
      player.speed = state.speed;
      player.angle = state.angle;
      player.x = state.x;
      return player.y = state.y;
    };
    Universe.prototype.connect = function() {
      var socket;
      socket = new io.Socket("127.0.0.1");
      socket.connect();
      socket.on('message', __bind(function(msg) {
        var req;
        req = JSON.parse(msg);
        return this[req.action](req.data);
      }, this));
      return socket;
    };
    Universe.prototype.drawPlayer = function(player) {
      var x, y, _ref;
      _ref = this.coordToPos(player.x, player.y), x = _ref[0], y = _ref[1];
      this.context.save();
      this.context.translate(x, y);
      this.context.rotate(player.angle);
      this.context.translate(-4, -3);
      this.context.fillStyle = "#fff";
      this.context.fillRect(0, 0, 8, 8);
      this.context.fillStyle = "red";
      this.context.fillRect(0, 0 + 8, 8, 2);
      return this.context.restore();
    };
    return Universe;
  })();
  document.addEventListener("DOMContentLoaded", function() {
    var universe;
    return universe = new Universe();
  });
}).call(this);
