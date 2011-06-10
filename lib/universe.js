(function() {
  var Player, Powerup, Universe, constants, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Player = require('player');
  Powerup = require('powerup');
  util = require('util');
  constants = require('constants');
  module.exports = Universe = (function() {
    function Universe(starting_name) {
      this.self;
      this.players = {};
      this.powerups = [];
      this.tick_count = 0;
      this.starting_name = starting_name;
      this.is_drawing;
      this.draw_buf = [];
      this.board = document.getElementById("universe");
      this.context = this.board.getContext("2d");
      this.connect();
    }
    Universe.prototype.gameTick = function() {
      var id, player, _ref;
      this.tick_count++;
      this.board.width = this.board.width;
      if (this.powerups.length < constants.maxPowerups && this.tick_count % constants.powerupTimer === 0) {
        this.addPowerup();
      }
      this.drawOverlay();
      this.drawPowerups();
      _ref = this.players;
      for (id in _ref) {
        player = _ref[id];
        this.tickPlayer(player);
      }
      this.syncSelf();
      this.handleDeath();
      return setTimeout((__bind(function() {
        return this.gameTick();
      }, this)), 40);
    };
    Universe.prototype.drawOverlay = function() {
      this.drawStats();
      this.drawEnergyMeter();
      return this.drawPlayerList();
    };
    Universe.prototype.addPowerup = function() {
      var powerup, x, y;
      x = Math.random() * this.board.width;
      y = Math.random() * this.board.height;
      console.log("adding powerup " + x + ", " + y);
      powerup = new Powerup(x, y);
      return this.powerups.push(powerup);
    };
    Universe.prototype.drawPowerups = function() {
      var powerup, _i, _len, _ref, _results;
      _ref = this.powerups;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        powerup = _ref[_i];
        _results.push(powerup.draw(this.context));
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
        this.context.fillText("" + (parseInt(player.damage)) + " " + player.name, x, y);
        _results.push(y += 10);
      }
      return _results;
    };
    Universe.prototype.drawStats = function() {
      var toTargAngle, totarget;
      this.context.fillStyle = "#fff";
      this.context.fillText("x: " + (parseInt(this.self.position.x)), 10, 10);
      this.context.fillText("y: " + (parseInt(this.self.position.y)), 10, 20);
      this.context.fillText("angle: " + this.self.position.angle, 10, 30);
      this.context.fillText("speed: " + this.self.speed, 10, 40);
      this.context.fillText("thrust: " + this.self.energy, 10, 50);
      this.context.fillText("id: " + this.self.id, 10, 60);
      this.context.fillText("dead: " + this.self.dead, 10, 70);
      this.context.fillText("pressn: " + (this.self.controls.anyPressed()), 10, 80);
      if (this.self.controls.target) {
        this.context.fillText("targetx: " + this.self.controls.target.x, 10, 90);
        this.context.fillText("targetx: " + this.self.controls.target.y, 10, 100);
      } else {
        this.context.fillText("No touch target!", 10, 90);
        this.context.fillText("", 10, 100);
      }
      totarget = util.subtractVec(this.self.controls.target, this.self.position);
      toTargAngle = Math.PI + Math.atan2(totarget.x, totarget.y);
      this.context.fillText("Target angle: " + toTargAngle, 10, 110);
      this.context.fillText("ToTarget vectorx: " + totarget.x, 10, 120);
      this.context.fillText("ToTarget vectory: " + totarget.y, 10, 130);
      this.context.fillText("DistToTarget: " + util.distanceFrom(this.self.position, this.self.controls.target), 10, 140);
      return this.context.fillText("Want to turn: " + (toTargAngle - this.self.position.angle), 10, 150);
    };
    Universe.prototype.syncSelf = function() {
      return this.socket.send(this.self.serialized());
    };
    Universe.prototype.tickPlayer = function(player) {
      var i, id, powerup, target, _ref, _ref2;
      if (player.position.x <= 0 || player.position.x >= this.board.width) {
        player.position.angle = 2 * Math.PI - player.position.angle;
      } else if (player.position.y >= this.board.height || player.position.y <= 0) {
        player.position.angle = Math.PI - player.position.angle;
      }
      _ref = this.powerups;
      for (i in _ref) {
        powerup = _ref[i];
        if (powerup.contains(player.position)) {
          powerup.apply_bonus(player);
          this.powerups.splice(i, 1);
        }
      }
      player.gameTick();
      _ref2 = this.players;
      for (id in _ref2) {
        target = _ref2[id];
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
    Universe.prototype.disableControls = function() {
      this.board.removeEventListener("mousedown");
      document.removeEventListener("keyup");
      return document.removeEventListener("keydown");
    };
    Universe.prototype.enableControls = function() {
      this.board.addEventListener("mousedown", __bind(function(e) {
        if (!(e.target === this.board && !this.self.controls.anyPressed())) {
          return;
        }
        this.self.controls.target = {
          x: e.clientX - this.board.offsetLeft,
          y: e.clientY - this.board.offsetTop
        };
        this.self.controls.mousedown = true;
        this.is_drawing = true;
        return this.draw_buf = [];
      }, this), false);
      this.board.addEventListener("mousemove", __bind(function(e) {
        if (!(this.is_drawing || (!this.self.controls.anyPressed() && this.self.controls.mouseDown))) {
          return;
        }
        this.self.controls.target = {
          x: e.clientX - this.board.offsetLeft,
          y: e.clientY - this.board.offsetTop
        };
        return this.draw_buf.push(e.clientX, e.clientY);
      }, this), false);
      this.board.addEventListener("mouseup", __bind(function(e) {
        this.self.controls.mouseDown = false;
        if (!this.is_drawing) {
          return;
        }
        return this.is_drawing = false;
      }, this), false);
      document.addEventListener("keyup", __bind(function(e) {
        switch (e.keyCode) {
          case 87:
          case 73:
            this.self.controls.wPressed = false;
            break;
          case 68:
          case 76:
            this.self.controls.dPressed = false;
            break;
          case 65:
          case 74:
            this.self.controls.aPressed = false;
            break;
          case 32:
            this.self.controls.spacePressed = false;
            break;
          case 83:
          case 75:
            this.self.controls.sPressed = false;
        }
        return this.syncSelf();
      }, this), false);
      return document.addEventListener("keydown", __bind(function(e) {
        this.self.controls.target = false;
        switch (e.keyCode) {
          case 87:
          case 73:
            this.self.controls.wPressed = true;
            break;
          case 68:
          case 76:
            this.self.controls.dPressed = true;
            break;
          case 65:
          case 74:
            this.self.controls.aPressed = true;
            break;
          case 32:
            this.self.controls.spacePressed = true;
            break;
          case 83:
          case 75:
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
      if (!player || player.id === this.self.id || player.dead) {
        return;
      }
      return player.update(state);
    };
    Universe.prototype.connect = function() {
      this.socket = new io.Socket(window.location.hostname);
      this.socket.connect();
      this.socket.on('disconnect', function() {
        var players;
        players = {};
        this.self = null;
        return this.disableControls();
      });
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
    Universe.prototype.handleDeath = function() {
      if (this.self.damage > constants.deadlyDamage || this.self.dead) {
        this.self.dead++;
        if (this.self.dead === 1) {
          console.log("" + this.self.name + " died at tick " + this.tick_count);
          this.self.damage = "dead";
          return this.self.trail = [];
        } else if (this.self.dead >= constants.deathAnimationTime) {
          this.self.damage = 0;
          this.self.dead = 0;
          this.self.position.x = Math.random() * constants.universeWidth;
          this.self.position.y = Math.random() * constants.universeHeight;
          return this.self.flash = 1;
        }
      }
    };
    return Universe;
  })();
}).call(this);
