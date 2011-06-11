express = require 'express'
io = require 'socket.io'
fs = require 'fs'
stitch = require 'stitch'
util = require './util.js'
OAuth = require('oauth').OAuth

client_id = 1
app = express.createServer()
socket = io.listen app
players = []
package = stitch.createPackage paths: [__dirname]

app.set "view engine", "eco"
app.configure ->
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session secret: "penus"
  app.use app.router
  app.use express.static "#{__dirname}/../public"

app.get "/client.js", package.createServer()

app.get "/", (req, res) ->
  if !req.session.oauth_access_token
    res.redirect "/login"
  else
    res.redirect "/game"

app.get "/game", (req, res) ->
  res.render "game", {screen_name: req.session.screen_name || "", colors: req.session.colors || []}

app.get "/login", (req, res) ->
  res.render "login"

app.get "/dragon.xml", (req, res) ->
  res.contentType "application/dragon+xml"
  res.partial "dragon",
    name: req.session.screen_name || "",
    colors: req.session.colors || util.randomColor() for [0 .. 4]

app.get "/twitter_login", (req, res) ->
  oa = new OAuth "https://api.twitter.com/oauth/request_token",
                 "https://api.twitter.com/oauth/access_token",
                 "eDkNl5jsrxZAUnKTx1nAjA",
                  process.env.DRAGONSTRYFE_OAUTH_SECRET,
                 "1.0",
                 "http://localhost:8081/login_success",
                 "HMAC-SHA1"

  oa.getOAuthRequestToken (error, token, token_secret, results) ->
    if error
      console.log "error", error
      res.redirect "/"
    else
      req.session.oa = oa
      req.session.oauth_token = token
      req.session.oatuh_token_secret = token_secret
      res.redirect "https://twitter.com/oauth/authenticate?oauth_token=#{token}"

app.get "/login_success", (req, res) ->
  oa = new OAuth req.session.oa._requestUrl,
                 req.session.oa._accessUrl,
                 req.session.oa._consumerKey,
                 req.session.oa._consumerSecret,
                 req.session.oa._version,
                 req.session.oa._authorize_callback,
                 req.session.oa._signatureMethod

  oa.getOAuthAccessToken req.session.oauth_token,
    req.session.oauth_token_secret,
    req.param('oauth_verifier'),
    (error, access_token, access_token_secret, results) ->
      if error
        console.log 'error', error
        res.redirect "/"
      else
        req.session.oauth_access_token = access_token
        req.session.oauth_access_token_secret = access_token_secret
        oa.getProtectedResource "http://api.twitter.com/1/account/verify_credentials.json",
          "GET",
          req.session.oauth_access_token,
          req.session.oauth_access_token_secret,
          (error, data, response) ->
            feed = JSON.parse(data)
            req.session.screen_name = feed.screen_name
            req.session.colors = [
              feed.profile_sidebar_border_color,
              feed.profile_sidebar_fill_color,
              feed.profile_link_color,
              feed.profile_text_color,
              feed.profile_background_color,
            ]
            res.redirect "/"

broadcast = (action, data) ->
  body = JSON.stringify {action: action, data: data}
  player.client.send body for player in players

send = (player, action, data) ->
  body = JSON.stringify {action: action, data: data}
  player.client.send body

socket.on "connection", (client) ->
  self =
    client: client
    state:
      id: client_id++

  # send client their starting position and id
  send(self, "initSelf", self.state)
  # send existing players to new player
  send(self, "addPlayers", player.state for player in players)
  # send new player to existing players
  broadcast("addPlayer", self.state)
  # add ourself to the list of players
  players.push self

  client.on "message", (msg) ->
    # update our state and broadcast it
    self.state = msg
    broadcast("syncPlayer", self.state)

  client.on "disconnect", ->
    index = players.indexOf self
    return if index == -1
    players.splice index, 1
    broadcast("removePlayer", self.state.id)

app.listen process.env.PORT || 8081
