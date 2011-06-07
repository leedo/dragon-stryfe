(function() {
  var app, broadcast, client_id, express, fs, io, package, players, send, socket, stitch;
  express = require('express');
  io = require('socket.io');
  fs = require('fs');
  stitch = require('stitch');
  client_id = 1;
  app = express.createServer();
  socket = io.listen(app);
  players = [];
  package = stitch.createPackage({
    paths: [__dirname]
  });
  app.configure(function() {
    return app.use(express.static("" + __dirname + "/../public"));
  });
  app.get("/client.js", package.createServer());
  app.get("/", function(req, res) {
    return res.redirect("/game.html");
  });
  broadcast = function(action, data) {
    var body, player, _i, _len, _results;
    body = JSON.stringify({
      action: action,
      data: data
    });
    _results = [];
    for (_i = 0, _len = players.length; _i < _len; _i++) {
      player = players[_i];
      _results.push(player.client.send(body));
    }
    return _results;
  };
  send = function(player, action, data) {
    var body;
    body = JSON.stringify({
      action: action,
      data: data
    });
    return player.client.send(body);
  };
  socket.on("connection", function(client) {
    var player, self;
    self = {
      client: client,
      state: {
        id: client_id++,
        name: client_id,
        speed: 0,
        angle: 0,
        x: 0,
        y: 0,
        trail: [],
        thrusting: false
      }
    };
    send(self, "initSelf", self.state);
    send(self, "addPlayers", (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = players.length; _i < _len; _i++) {
        player = players[_i];
        _results.push(player.state);
      }
      return _results;
    })());
    broadcast("addPlayer", self.state);
    players.push(self);
    client.on("message", function(msg) {
      var field, _i, _len, _ref;
      _ref = ["name", "speed", "angle", "x", "y", "trail", "thrusting"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        self.state[field] = msg[field];
      }
      return broadcast("syncPlayer", self.state);
    });
    return client.on("disconnect", function() {
      var index;
      index = players.indexOf(self);
      if (index === -1) {
        return;
      }
      players.splice(index, 1);
      return broadcast("removePlayer", self.state.id);
    });
  });
  app.listen(process.env.PORT || 8081);
}).call(this);
