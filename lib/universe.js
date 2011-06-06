(function() {
  var Universe, player, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  player = require('player');
  util = require('util');
  exports.bang = function() {
    return new Universe();
  };
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
      this.drawThrustMeter();
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
      this.context.fillText("angle: " + this.self.angle, 10, 30);
      this.context.fillText("speed: " + this.self.speed, 10, 40);
      return this.context.fillText("thrust: " + this.self.thrust, 10, 50);
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
      this.self = player.createSelf(state);
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
            this.self.thrusting = false;
            return this.self.controls.wPressed = false;
          case 68:
            return this.self.controls.dPressed = false;
          case 65:
            return this.self.controls.aPressed = false;
        }
      }, this), false);
      return document.addEventListener("keydown", __bind(function(e) {
        switch (e.keyCode) {
          case 87:
            if (this.self.thrust) {
              this.self.thrusting = true;
            }
            return this.self.controls.wPressed = true;
          case 68:
            return this.self.controls.dPressed = true;
          case 65:
            return this.self.controls.aPressed = true;
        }
      }, this), false);
    };
    Universe.prototype.removePlayer = function(id) {
      console.log("remove player " + id);
      return delete this.players[id];
    };
    Universe.prototype.addPlayer = function(state) {
      console.log("add player " + state.id);
      player = player.createPlayer(state);
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
      var field, _i, _len, _ref, _results;
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
    Universe.prototype.drawThrustMeter = function() {
      var i, x, y, _ref, _results;
      _ref = [this.board.width - 30, this.board.height - 10], x = _ref[0], y = _ref[1];
      _results = [];
      for (i = 0; i <= 10; i++) {
        this.context.fillStyle = i * 10 <= this.self.thrust ? "red" : "#ccc";
        this.context.fillRect(x, y, 20, 5);
        _results.push(y -= 10);
      }
      return _results;
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
  window.Universe = Universe;
}).call(this);
