(function() {
  var OAuth, app, broadcast, constants, express, fs, game, io, next_id, object_id, package, send, send_powerup, socket, stitch, util;
  express = require('express');
  io = require('socket.io');
  fs = require('fs');
  stitch = require('stitch');
  util = require('./util.js');
  constants = require("./constants.js");
  OAuth = require('oauth').OAuth;
  app = express.createServer();
  socket = io.listen(app);
  package = stitch.createPackage({
    paths: [__dirname]
  });
  object_id = 1;
  next_id = function() {
    return object_id++;
  };
  game = {
    clients: {},
    players: {},
    powerups: {}
  };
  app.set("view engine", "eco");
  app.configure(function() {
    app.use(express.logger());
    app.use(express.bodyParser());
    app.use(express.cookieParser());
    app.use(express.session({
      secret: "penus"
    }));
    app.use(app.router);
    return app.use(express.static("" + __dirname + "/../public"));
  });
  app.get("/client.js", package.createServer());
  app.get("/", function(req, res) {
    if (!req.session.oauth_access_token) {
      return res.redirect("/login");
    } else {
      return res.redirect("/game");
    }
  });
  app.get("/game", function(req, res) {
    req.session.client_id = next_id();
    return res.render("game", {
      screen_name: req.session.screen_name || "",
      colors: req.session.colors || [],
      client_id: req.session.client_id
    });
  });
  app.get("/login", function(req, res) {
    return res.render("login");
  });
  app.get("/dragon.xml", function(req, res) {
    res.contentType("application/dragon+xml");
    return res.partial("dragon", {
      name: req.session.screen_name || "",
      colors: (function() {
        var _i, _results;
        _results = [];
        for (_i = 0; _i <= 4; _i++) {
          _results.push(req.session.colors || util.randomColor());
        }
        return _results;
      })()
    });
  });
  app.get("/twitter_login", function(req, res) {
    var oa;
    oa = new OAuth("https://api.twitter.com/oauth/request_token", "https://api.twitter.com/oauth/access_token", "eDkNl5jsrxZAUnKTx1nAjA", process.env.DRAGONSTRYFE_OAUTH_SECRET, "1.0", "http://localhost:8081/login_success", "HMAC-SHA1");
    return oa.getOAuthRequestToken(function(error, token, token_secret, results) {
      if (error) {
        console.log("error", error);
        return res.redirect("/");
      } else {
        req.session.oa = oa;
        req.session.oauth_token = token;
        req.session.oatuh_token_secret = token_secret;
        return res.redirect("https://twitter.com/oauth/authenticate?oauth_token=" + token);
      }
    });
  });
  app.get("/login_success", function(req, res) {
    var oa;
    oa = new OAuth(req.session.oa._requestUrl, req.session.oa._accessUrl, req.session.oa._consumerKey, req.session.oa._consumerSecret, req.session.oa._version, req.session.oa._authorize_callback, req.session.oa._signatureMethod);
    return oa.getOAuthAccessToken(req.session.oauth_token, req.session.oauth_token_secret, req.param('oauth_verifier'), function(error, access_token, access_token_secret, results) {
      if (error) {
        console.log('error', error);
        return res.redirect("/");
      } else {
        req.session.oauth_access_token = access_token;
        req.session.oauth_access_token_secret = access_token_secret;
        return oa.getProtectedResource("http://api.twitter.com/1/account/verify_credentials.json", "GET", req.session.oauth_access_token, req.session.oauth_access_token_secret, function(error, data, response) {
          var feed;
          feed = JSON.parse(data);
          req.session.screen_name = feed.screen_name;
          req.session.colors = [feed.profile_sidebar_border_color, feed.profile_sidebar_fill_color, feed.profile_link_color, feed.profile_text_color, feed.profile_background_color];
          return res.redirect("/");
        });
      }
    });
  });
  broadcast = function(action, data) {
    var body, client, id, _ref, _results;
    body = JSON.stringify({
      action: action,
      data: data
    });
    _ref = game.clients;
    _results = [];
    for (id in _ref) {
      client = _ref[id];
      _results.push(client.send(body));
    }
    return _results;
  };
  send = function(client, action, data) {
    var body;
    body = JSON.stringify({
      action: action,
      data: data
    });
    return client.send(body);
  };
  socket.on("connection", function(client) {
    var id, player, powerup, self;
    self = {
      client: client
    };
    send(client, "addPlayers", (function() {
      var _ref, _results;
      _ref = game.players;
      _results = [];
      for (id in _ref) {
        player = _ref[id];
        _results.push(player);
      }
      return _results;
    })());
    send(client, "addPowerups", (function() {
      var _ref, _results;
      _ref = game.powerups;
      _results = [];
      for (id in _ref) {
        powerup = _ref[id];
        _results.push(powerup);
      }
      return _results;
    })());
    client.on("message", function(msg) {
      var k, v, _ref;
      switch (msg.action) {
        case "initSelf":
          broadcast("addPlayer", msg.data);
          self.player = msg.data;
          self.id = msg.source;
          game.players[msg.source] = msg.data;
          return game.clients[msg.source] = client;
        case "syncSelf":
          _ref = msg.data;
          for (k in _ref) {
            v = _ref[k];
            self.player[k] = v;
          }
          return broadcast("syncPlayer", msg.data);
        case "removePowerup":
          delete game.powerups[msg.data];
          return broadcast("removePowerup", msg.id);
      }
    });
    return client.on("disconnect", function() {
      broadcast("removePlayer", self.id);
      delete game.players[self.id];
      return delete game.clients[self.id];
    });
  });
  send_powerup = function() {
    var powerup, x, y;
    if (Object.keys(game.powerups).length < constants.maxPowerups) {
      x = Math.random() * constants.universeWidth;
      y = Math.random() * constants.universeHeight;
      powerup = {
        id: next_id(),
        x: x,
        y: y
      };
      game.powerups[powerup.id] = powerup;
      broadcast("addPowerup", powerup);
    }
    return setTimeout(send_powerup, 10 + Math.random() * 10000);
  };
  send_powerup();
  app.listen(process.env.PORT || 8081);
}).call(this);
