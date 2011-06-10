(function() {
  var OAuth, app, broadcast, client_id, express, fs, io, package, players, send, socket, stitch;
  express = require('express');
  io = require('socket.io');
  fs = require('fs');
  stitch = require('stitch');
  OAuth = require('oauth').OAuth;
  client_id = 1;
  app = express.createServer();
  socket = io.listen(app);
  players = [];
  package = stitch.createPackage({
    paths: [__dirname]
  });
  app.set("view engine", "eco");
  app.configure(function() {
    app.use(express.logger());
    app.use(express.bodyParser());
    app.use(express.cookieParser());
    app.use(express.session({
      secret: "penus"
    }));
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
    return res.render("game", {
      screen_name: req.session.screen_name || "",
      colors: req.session.colors || []
    });
  });
  app.get("/login", function(req, res) {
    return res.render("login");
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
        id: client_id++
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
      self.state = msg;
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
