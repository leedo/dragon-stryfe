(function() {
  var Player, Powerup, Universe, constants, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Player = require('player');
  Powerup = require('powerup');
  util = require('util');
  constants = require('constants');
  module.exports = Universe = (function() {
    function Universe(id, name, colors) {
      this.player_map = {};
      this.powerup_map = {};
      this.tick_count = 0;
      this.stopped = true;
      this.is_touching = false;
      this.board = document.getElementById("universe");
      this.context = this.board.getContext("2d");
      this.createSelf(id, name, colors);
      this.connect();
    }
    Universe.prototype.startGame = function() {
      this.stopped = false;
      this.player_map[this.self.id] = this.self;
      this.enableControls();
      return this.gameTick();
    };
    Universe.prototype.stopGame = function() {
      this.stopped = true;
      this.tick_count = 0;
      return this.player_map = {};
    };
    Universe.prototype.createSelf = function(id, name, colors) {
      console.log("create self with id " + id);
      if (!name) {
        name = prompt("What is your dragon's name?");
        name = name.substr(0, 16);
      }
      return this.self = new Player({
        id: id,
        name: name,
        body_color: colors[4] || util.randomColor(),
        highlight_color: colors[2] || util.randomColor(),
        x: this.board.width / 2,
        y: this.board.height / 2
      });
    };
    Universe.prototype.gameTick = function() {
      var diff, id, player, start, _ref;
      if (this.stopped) {
        return;
      }
      start = (new Date()).getTime();
      this.tick_count++;
      this.board.width = this.board.width;
      this.drawPowerups();
      _ref = this.players();
      for (id in _ref) {
        player = _ref[id];
        this.tickPlayer(player);
      }
      this.checkDeath();
      this.drawOverlay();
      this.syncSelf();
      diff = Math.max(0, (new Date()).getTime() - start);
      return setTimeout((__bind(function() {
        return this.gameTick();
      }, this)), 40 - diff);
    };
    Universe.prototype.tickPlayer = function(player) {
      var id, powerup, target, _ref, _ref2;
      if (player.x <= 0 || player.x >= this.board.width) {
        player.angle = 2 * Math.PI - player.angle;
      } else if (player.y >= this.board.height || player.y <= 0) {
        player.angle = Math.PI - player.angle;
      }
      _ref = this.powerups;
      for (id in _ref) {
        powerup = _ref[id];
        if (powerup.contains(player)) {
          powerup.apply_bonus(player);
          this.removePowerup(id);
          if (player.id === this.self.id) {
            this.sendAction("removePowerup", id);
          }
        }
      }
      player.gameTick();
      _ref2 = this.players();
      for (id in _ref2) {
        target = _ref2[id];
        player.tryToBreath(target);
      }
      player.draw(this.context);
      return player.drawName(this.context, player !== this.self);
    };
    Universe.prototype.players = function() {
      var id, player, _ref, _results;
      _ref = this.player_map;
      _results = [];
      for (id in _ref) {
        player = _ref[id];
        _results.push(player);
      }
      return _results;
    };
    Universe.prototype.getPlayer = function(id) {
      return this.player_map[id];
    };
    Universe.prototype.removePlayer = function(id) {
      console.log("remove player " + id);
      return delete this.player_map[id];
    };
    Universe.prototype.addPlayer = function(state) {
      var player;
      console.log("add player " + state.id, state);
      player = new Player(state);
      this.player_map[player.id] = player;
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
      var k, player, v, _results;
      player = this.getPlayer(state.id);
      if (!player || player.id === this.self.id) {
        return;
      }
      _results = [];
      for (k in state) {
        v = state[k];
        _results.push(player[k] = v);
      }
      return _results;
    };
    Universe.prototype.powerups = function() {
      var id, powerup, _len, _ref, _results;
      _ref = this.powerup_map;
      _results = [];
      for (powerup = 0, _len = _ref.length; powerup < _len; powerup++) {
        id = _ref[powerup];
        _results.push(powerup);
      }
      return _results;
    };
    Universe.prototype.removePowerup = function(id) {
      return delete this.powerups[id];
    };
    Universe.prototype.addPowerup = function(opts) {
      console.log("add powerup");
      return this.powerups[opts.id] = new Powerup(opts);
    };
    Universe.prototype.addPowerups = function(new_powerups) {
      var state, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = new_powerups.length; _i < _len; _i++) {
        state = new_powerups[_i];
        _results.push(this.powerups[state.id] = new Powerup(state));
      }
      return _results;
    };
    Universe.prototype.syncScore = function(data) {
      var player;
      player = this.getPlayer(data.id);
      return player.kills = data.score;
    };
    Universe.prototype.drawOverlay = function() {
      this.drawEnergyMeter();
      this.drawHealthMeter();
      return this.drawPlayerList();
    };
    Universe.prototype.drawPowerups = function() {
      var id, powerup, _ref, _results;
      _ref = this.powerups;
      _results = [];
      for (id in _ref) {
        powerup = _ref[id];
        _results.push(powerup.draw(this.context));
      }
      return _results;
    };
    Universe.prototype.drawPlayerList = function() {
      var player, players, x, y, _i, _len, _ref, _results;
      _ref = [this.board.width - 100, 100], x = _ref[0], y = _ref[1];
      this.context.fillStyle = "#fff";
      players = this.players().sort(function(a, b) {
        return b.kills - a.kills;
      });
      _results = [];
      for (_i = 0, _len = players.length; _i < _len; _i++) {
        player = players[_i];
        this.context.fillText("" + (parseInt(player.kills)) + " " + player.name, x, y);
        _results.push(y += 10);
      }
      return _results;
    };
    Universe.prototype.drawStats = function() {
      var toTargAngle, totarget;
      this.context.fillStyle = "#fff";
      this.context.fillText("x: " + (parseInt(this.self.x)), 10, 10);
      this.context.fillText("y: " + (parseInt(this.self.y)), 10, 20);
      this.context.fillText("angle: " + this.self.angle, 10, 30);
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
      totarget = util.subtractVec(this.self.controls.target, this.self);
      toTargAngle = Math.PI + Math.atan2(totarget.x, totarget.y);
      this.context.fillText("Target angle: " + toTargAngle, 10, 110);
      this.context.fillText("ToTarget vectorx: " + totarget.x, 10, 120);
      this.context.fillText("ToTarget vectory: " + totarget.y, 10, 130);
      this.context.fillText("DistToTarget: " + util.distanceFrom(this.self, this.self.controls.target), 10, 140);
      return this.context.fillText("Want to turn: " + (toTargAngle - this.self.angle), 10, 150);
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
        return this.is_touching = true;
      }, this), false);
      this.board.addEventListener("mousemove", __bind(function(e) {
        if (!(this.is_touching || (!this.self.controls.anyPressed() && this.self.controls.mouseDown))) {
          return;
        }
        return this.self.controls.target = {
          x: e.clientX - this.board.offsetLeft,
          y: e.clientY - this.board.offsetTop
        };
      }, this), false);
      this.board.addEventListener("mouseup", __bind(function(e) {
        this.self.controls.mouseDown = false;
        if (!this.is_touching) {
          return;
        }
        return this.is_touching = false;
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
            e.preventDefault();
            break;
          case 83:
          case 75:
            this.self.controls.sPressed = true;
        }
        return this.syncSelf();
      }, this), false);
    };
    Universe.prototype.syncSelf = function() {
      return this.sendAction("syncSelf", this.self.serialized());
    };
    Universe.prototype.connect = function() {
      this.socket = new io.Socket(window.location.hostname);
      this.socket.on('connect', __bind(function() {
        this.sendAction("initSelf", this.self.serialized(true));
        return this.startGame();
      }, this));
      this.socket.on('disconnect', __bind(function() {
        return this.stopGame();
      }, this));
      this.socket.on('message', __bind(function(msg) {
        var req;
        req = JSON.parse(msg);
        return this[req.action](req.data);
      }, this));
      return this.socket.connect();
    };
    Universe.prototype.drawEnergyMeter = function() {
      var width, x, y, _ref;
      _ref = [10, 35], x = _ref[0], y = _ref[1];
      util.drawOutlinedText(this.context, "Energy", x, y);
      y += 3;
      this.context.fillStyle = "rgba(255,255,255,0.2)";
      this.context.fillRect(x, y, 100, 5);
      this.context.fillStyle = "yellow";
      width = 100 * (this.self.energy / constants.maxEnergy);
      return this.context.fillRect(x, y, width, 5);
    };
    Universe.prototype.drawHealthMeter = function() {
      var percent, x, y, _ref;
      _ref = [10, 15], x = _ref[0], y = _ref[1];
      util.drawOutlinedText(this.context, "Health", x, y);
      y += 3;
      this.context.fillStyle = "rgba(255,255,255,0.2)";
      this.context.fillRect(x, y, 100, 5);
      percent = this.self.hpPercent();
      this.context.fillStyle = percent > .2 ? "green" : "red";
      return this.context.fillRect(x, y, percent * 100, 5);
    };
    Universe.prototype.sendAction = function(action, data) {
      return this.socket.send({
        source: this.self.id,
        action: action,
        data: data
      });
    };
    Universe.prototype.checkDeath = function() {
      if (this.self.damage > constants.deadlyDamage || this.self.dead) {
        if (this.self.dead === 0) {
          console.log("" + this.self.name + " died at tick " + this.tick_count);
          this.sendAction("scorePoint", this.self.last_attacker);
          return this.self.dead = 1;
        } else if (this.self.dead >= constants.deathAnimationTime) {
          this.self.damage = 0;
          this.self.dead = 0;
          this.self.x = Math.random() * constants.universeWidth;
          this.self.y = Math.random() * constants.universeHeight;
          this.self.flash = 1;
          return this.self.energy = constants.maxEnergy;
        }
      }
    };
    return Universe;
  })();
}).call(this);
