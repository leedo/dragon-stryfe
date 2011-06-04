(function() {
  var app, broadcast, client_id, express, fs, io, players, send, socket, type_map;
  express = require('express');
  io = require('socket.io');
  fs = require('fs');
  client_id = 1;
  app = express.createServer();
  socket = io.listen(app);
  players = [];
  type_map = {
    js: "text/javascript",
    css: "text/css",
    html: "text/html"
  };
  app.get("/", function(req, res) {
    return res.redirect("/game.html");
  });
  app.get(/^\/(.+\.(html|css|js))/, function(req, res) {
    var ext, file, _ref;
    _ref = req.params, file = _ref[0], ext = _ref[1];
    return fs.readFile(file, function(err, body) {
      if (err) {
        return res.send(404);
      } else {
        return res.send(body, {
          'Content-Type': type_map[ext]
        }, 200);
      }
    });
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
        x: 0,
        y: 0
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
      if (msg.x) {
        self.state.x = msg.x;
      }
      if (msg.y) {
        self.state.y = msg.y;
      }
      return broadcast("updatePlayer", self.state);
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
  app.listen(8081);
}).call(this);
