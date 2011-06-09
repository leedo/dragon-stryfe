(function() {
  var Player, Universe, constants, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Player = require('player');
  util = require('util');
  constants = require('constants');
  module.exports = Universe = (function() {
    function Universe(starting_name) {
      this.self;
      this.players = {};
      this.powerups = [];
      this.tick_count = 0;
      this.starting_name = starting_name;
      this.board = document.getElementById("universe");
      this.context = this.board.getContext("2d");
      this.is_drawing;
      this.draw_buf = [];
      this.connect();
    }
    Universe.prototype.gameTick = function() {
      var id, player, _ref;
      this.tick_count++;
      this.board.width = this.board.width;
      this.drawOverlay();
      this.context.save();
      _ref = this.players;
      for (id in _ref) {
        player = _ref[id];
        this.tickPlayer(player);
      }
      this.updatePowerups();
      if (this.self.damage > constants.deadlyDamage || this.self.dead) {
        this.self.dead++;
        if (this.self.dead === 1) {
          console.log("" + this.self.name + " died at tick " + this.tick_count);
          this.self.damage = "dead";
          this.self.trail = [];
          this.self.updateTrail();
        } else if (this.self.dead >= constants.deathAnimationTime) {
          this.self.damage = 0;
          this.self.dead = 0;
          this.self.position.x = Math.random() * this.board.width;
          this.self.position.y = Math.random() * this.board.height;
          this.self.flash = 1;
        }
      }
      if (this.tick_count % constants.syncTimer) {
        this.syncSelf();
      }
      return setTimeout((__bind(function() {
        return this.gameTick();
      }, this)), 40);
    };
    Universe.prototype.updatePowerups = function() {
      var id, player, powerup, _i, _len, _ref, _ref2;
      if (this.powerups.length < 1) {
        if ((Math.random() * 10000) > 9950) {
          this.powerups.push({
            x: Math.random() * this.board.width - 5,
            y: Math.random() * this.board.height - 5
          });
        }
      }
      this.drawPowerups();
      _ref = this.players;
      for (id in _ref) {
        player = _ref[id];
        _ref2 = this.powerups;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          powerup = _ref2[_i];
          if ((player.position.x + 10) > (powerup.x - 5) && (player.position.x - 10) < (powerup.x + 5) && (player.position.y + 10) > (powerup.y - 5) && (player.position.y - 10) < (powerup.y + 5)) {
            this.powerups.pop();
            player.energy = constants.maxEnergy;
          }
        }
      }
      return null;
    };
    Universe.prototype.drawOverlay = function() {
      this.drawStats();
      this.drawEnergyMeter();
      return this.drawPlayerList();
    };
    Universe.prototype.drawPowerups = function() {
      var powerup, _i, _len, _ref, _results;
      _ref = this.powerups;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        powerup = _ref[_i];
        this.context.fillStyle = "#ffff00";
        this.context.beginPath();
        this.context.arc(powerup.x, powerup.y, 5, 0, Math.PI * 2, true);
        this.context.closePath();
        this.context.stroke();
        _results.push(this.context.fill());
      }
      return _results;
    };
    Universe.prototype.drawPlayerList = function() {
      var id, player, x, y, _ref, _ref2, _results;
      _ref = [this.board.width - 100, 100], x = _ref[0], y = _ref[1];
      this.context.fillStyle = "#fff";
      _ref2 = this.players;
      _results = [];
      for (id in _ref2) {
        player = _ref2[id];
        this.context.fillText("" + player.damage + " " + player.name, x, y);
        _results.push(y += 10);
      }
      return _results;
    };
    Universe.prototype.drawStats = function() {
      this.context.fillStyle = "#fff";
      this.context.fillText("x: " + (parseInt(this.self.position.x)), 10, 10);
      this.context.fillText("y: " + (parseInt(this.self.position.y)), 10, 20);
      this.context.fillText("angle: " + this.self.position.angle, 10, 30);
      this.context.fillText("speed: " + this.self.speed, 10, 40);
      this.context.fillText("thrust: " + this.self.energy, 10, 50);
      this.context.fillText("id: " + this.self.id, 10, 60);
      return this.context.fillText("dead: " + this.self.dead, 10, 70);
    };
    Universe.prototype.syncSelf = function() {
      return this.socket.send(this.self.serialized());
    };
    Universe.prototype.tickPlayer = function(player) {
      var id, target, _ref;
      if (player.position.x <= 0 || player.position.x >= this.board.width) {
        player.position.angle = 2 * Math.PI - player.position.angle;
      } else if (player.position.y >= this.board.height || player.position.y <= 0) {
        player.position.angle = Math.PI - player.position.angle;
      }
      player.gameTick();
      _ref = this.players;
      for (id in _ref) {
        target = _ref[id];
        player.tryToBreath(target);
      }
      return player.draw(this.context);
    };
    Universe.prototype.initSelf = function(state) {
      console.log("init self with id " + state.id);
      state.x = this.board.width / 2;
      state.y = this.board.height / 2;
      if (!this.starting_name) {
        state.name = prompt("What is your dragon's name?");
        state.name = state.name.substr(0, 16);
      } else {
        state.name = this.starting_name;
      }
      this.self = this.addPlayer(state);
      this.enableControls();
      this.syncSelf();
      return this.gameTick();
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
        return this.is_drawing = false;
      }, this), false);
      document.addEventListener("keyup", __bind(function(e) {
        switch (e.keyCode) {
          case 87:
            this.self.controls.wPressed = false;
            break;
          case 68:
            this.self.controls.dPressed = false;
            break;
          case 65:
            this.self.controls.aPressed = false;
            break;
          case 32:
            this.self.controls.spacePressed = false;
            break;
          case 83:
            this.self.controls.sPressed = false;
        }
        return this.syncSelf();
      }, this), false);
      return document.addEventListener("keydown", __bind(function(e) {
        switch (e.keyCode) {
          case 87:
            this.self.controls.wPressed = true;
            break;
          case 68:
            this.self.controls.dPressed = true;
            break;
          case 65:
            this.self.controls.aPressed = true;
            break;
          case 32:
            this.self.controls.spacePressed = true;
            break;
          case 83:
            this.self.controls.sPressed = true;
        }
        return this.syncSelf();
      }, this), false);
    };
    Universe.prototype.removePlayer = function(id) {
      console.log("remove player " + id);
      return delete this.players[id];
    };
    Universe.prototype.addPlayer = function(state) {
      var player;
      console.log("add player " + state.id);
      state.max_x = this.board.width;
      state.max_y = this.board.height;
      player = new Player(state);
      this.players[player.id] = player;
      return player;
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
      if (!player || player.id === this.self.id) {
        return;
      }
      return player.update(state);
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
    Universe.prototype.drawEnergyMeter = function() {
      var i, x, y, _ref, _results;
      _ref = [this.board.width - 30, this.board.height - 10], x = _ref[0], y = _ref[1];
      _results = [];
      for (i = 0; i <= 10; i++) {
        this.context.fillStyle = i * 10 <= this.self.energy ? "red" : "#ccc";
        this.context.fillRect(x, y, 20, 5);
        _results.push(y -= 10);
      }
      return _results;
    };
    return Universe;
  })();
}).call(this);
