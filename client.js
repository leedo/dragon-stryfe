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
      this.sync = ["name", "speed", "angle", "x", "y", "trail", "thrusting"];
      this.x = opts.x || 0;
      this.y = opts.y || 0;
      this.speed = opts.speed || 0;
      this.angle = opts.angle || 0;
      this.id = opts.id;
      this.thrusting = opts.thrusting || false;
      this.name = opts.name || "unknown";
      this.trail = [];
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
      if (this.trail.length > 15) {
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
      Self.__super__.constructor.apply(this, arguments);
    }
    Self.prototype.handleInput = function() {
      if (this.turn !== 0) {
        this.angle += this.turn * 0.05;
      }
      if (this.thrusting && this.speed < 8) {
        return this.speed += 0.4;
      } else if (this.speed > 0.4) {
        return this.speed -= 0.1;
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
      this.tick_count = 0;
      this.board = document.getElementById("universe");
      this.board.width = document.width;
      this.board.height = document.height;
      this.context = this.board.getContext("2d");
      this.is_drawing;
      this.draw_buf = [];
      this.connect();
    }
    Universe.prototype.gameTick = function() {
      var id, player, _ref;
      this.board.width = this.board.width;
      this.drawInfo();
      this.context.save();
      if (this.self) {
        this.tickPlayer(this.self);
      }
      _ref = this.players;
      for (id in _ref) {
        player = _ref[id];
        this.tickPlayer(player);
      }
      if (this.self.x < 0 || this.self.y < 0 || this.self.x > this.board.width || this.self.y > this.board.height) {
        this.self.angle += Math.PI;
      }
      if (this.self.angle > Math.PI * 2.0) {
        this.self.angle -= Math.PI * 2.0;
      }
      if (this.self.angle < 0.0) {
        this.self.angle += Math.PI * 2.0;
      }
      return setTimeout((__bind(function() {
        return this.gameTick();
      }, this)), 40);
    };
    Universe.prototype.drawInfo = function() {
      this.context.fillStyle = "#fff";
      this.context.fillText("x: " + (parseInt(this.self.x)), 10, 10);
      this.context.fillText("y: " + (parseInt(this.self.y)), 10, 20);
      return this.context.fillText("angle: " + this.self.angle, 10, 30);
    };
    Universe.prototype.syncSelf = function() {
      this.self.updateTrail();
      this.socket.send(this.self.serialized());
      return setTimeout((__bind(function() {
        return this.syncSelf();
      }, this)), 100);
    };
    Universe.prototype.tickPlayer = function(player) {
      player.gameTick();
      return this.drawPlayer(player);
    };
    Universe.prototype.initSelf = function(state) {
      console.log("init self with id " + state.id);
      state.x = this.board.width / 2;
      state.y = this.board.height / 2;
      state.name = prompt("What is your dragon's name?");
      this.self = new Self(state);
      this.drawPlayer(this.self);
      this.enableControls();
      this.gameTick();
      return this.syncSelf();
    };
    Universe.prototype.enableControls = function() {
      this.board.addEventListener("mousedown", __bind(function(e) {
        if (e.target !== this.board) {
          return;
        }
        this.is_drawing = true;
        return this.draw_buf = [];
      }, this), false);
      this.board.addEventListener("mousemove", __bind(function(e) {
        if (!this.is_drawing) {
          return;
        }
        return this.draw_buf.push(e.clientX, e.clientY);
      }, this), false);
      this.board.addEventListener("mouseup", __bind(function(e) {
        if (!this.is_drawing) {
          return;
        }
        this.is_drawing = false;
        return console.log(this.draw_buf);
      }, this), false);
      document.addEventListener("keyup", __bind(function(e) {
        switch (e.keyCode) {
          case 87:
            return this.self.thrusting = false;
          case 68:
            return this.self.turn = 0;
          case 65:
            return this.self.turn = 0;
        }
      }, this), false);
      return document.addEventListener("keydown", __bind(function(e) {
        switch (e.keyCode) {
          case 87:
            return this.self.thrusting = true;
          case 68:
            return this.self.turn = -1;
          case 65:
            return this.self.turn = 1;
        }
      }, this), false);
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
      var field, player, _i, _len, _ref, _results;
      player = this.players[state.id];
      if (!player) {
        return;
      }
      _ref = player.sync;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        _results.push(player[field] = state[field]);
      }
      return _results;
    };
    Universe.prototype.connect = function() {
      this.socket = new io.Socket(window.location.hostname);
      this.socket.connect();
      return this.socket.on('message', __bind(function(msg) {
        var req;
        req = JSON.parse(msg);
        return this[req.action](req.data);
      }, this));
    };
    Universe.prototype.drawTrail = function(player) {
      var coord, opacity, x, y, _i, _len, _ref, _results;
      opacity = 0.3;
      _ref = player.trail;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        coord = _ref[_i];
        opacity -= 0.01;
        _results.push(coord ? ((x = coord[0], y = coord[1], coord), this.context.fillStyle = "rgba(255,255,255," + opacity + ")", this.context.fillRect(x, y, 8, 8)) : void 0);
      }
      return _results;
    };
    Universe.prototype.drawPlayer = function(player) {
      var x, y, _ref;
      this.drawTrail(player);
      _ref = [player.x, player.y], x = _ref[0], y = _ref[1];
      this.context.translate(x, y);
      this.context.fillStyle = "#fff";
      this.context.fillText(player.name, -4, -15);
      this.context.rotate(-player.angle);
      this.context.translate(-4, -3);
      this.context.fillStyle = "#fff";
      this.context.fillRect(0, 0, 8, 8);
      this.context.fillStyle = player.thrusting ? "red" : "rgba(255,255,255,0.5)";
      this.context.fillRect(0, 8, 8, 2);
      return this.context.restore();
    };
    return Universe;
  })();
  document.addEventListener("DOMContentLoaded", (function() {
    var universe;
    return universe = new Universe();
  }), false);
}).call(this);
