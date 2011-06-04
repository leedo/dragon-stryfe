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
      this.id = opts.id;
      this.elem = this.createShip();
    }
    Player.prototype.createShip = function() {
      var elem;
      elem = document.createElement("DIV");
      elem.id = "player-" + this.id;
      elem.className = "player";
      elem.style.left = this.x + "px";
      elem.style.top = this.y + "px";
      return elem;
    };
    Player.prototype.moveShip = function(x, y) {
      this.elem.style.left = x + "px";
      return this.elem.style.top = y + "px";
    };
    return Player;
  })();
  Self = (function() {
    __extends(Self, Player);
    function Self() {
      Self.__super__.constructor.apply(this, arguments);
    }
    Self.prototype.createShip = function() {
      var elem;
      elem = Self.__super__.createShip.apply(this, arguments);
      elem.className = "player self";
      return elem;
    };
    return Self;
  })();
  Universe = (function() {
    function Universe() {
      this.self;
      this.players = {};
      this.board = document.getElementById("board");
      this.socket = this.connect();
      setInterval(__bind(function() {
        console.log("players", this.players);
        return console.log("self", this.self);
      }, this), 10000);
      this.board.addEventListener("click", __bind(function(e) {
        if (!this.self) {
          return;
        }
        this.self.moveShip(e.x, e.y);
        return this.socket.send({
          x: e.x,
          y: e.y
        });
      }, this));
    }
    Universe.prototype.initSelf = function(state) {
      console.log("init self with id " + state.id);
      this.self = new Self(state);
      return this.board.appendChild(this.self.elem);
    };
    Universe.prototype.removePlayer = function(id) {
      var elem, player;
      console.log("remove player " + id);
      player = this.players[id];
      if (player) {
        elem = player.elem;
        elem.parentNode.removeChild(elem);
      }
      return delete this.players[id];
    };
    Universe.prototype.addPlayer = function(state) {
      var player;
      console.log("add player " + state.id);
      player = new Player(state);
      this.board.appendChild(player.elem);
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
    Universe.prototype.updatePlayer = function(state) {
      var player;
      console.log("update player " + state.id);
      player = this.players[state.id];
      if (!player) {
        return;
      }
      return player.moveShip(state.x, state.y);
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
    return Universe;
  })();
  document.addEventListener("DOMContentLoaded", function() {
    var universe;
    return universe = new Universe();
  });
}).call(this);
