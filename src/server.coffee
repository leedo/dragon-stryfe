express = require 'express'
io = require 'socket.io'
fs = require 'fs'
stitch = require 'stitch'
util = require './util.js'
constants = require "./constants.js"
OAuth = require('oauth').OAuth

app = express.createServer()
socket = io.listen app
package = stitch.createPackage paths: [__dirname]

object_id = 1
next_id = -> object_id++

game = {
  clients: {}
  players: {}
  powerups: {}
}

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
  req.session.client_id = next_id()
  res.render "game", {
    screen_name: req.session.screen_name || "",
    colors: req.session.colors || [],
    client_id: req.session.client_id
  }

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
  client.send body for id, client of game.clients

send = (client, action, data) ->
  body = JSON.stringify {action: action, data: data}
  client.send body

socket.on "connection", (client) ->
  self = {client: client}
  # send existing players to new player
  send(client, "addPlayers", player for id, player of game.players)
  send(client, "addPowerups", powerup for id, powerup of game.powerups)

  client.on "message", (msg) ->
    switch msg.action
      when "initSelf"
        broadcast("addPlayer", msg.data)
        self.player = msg.data
        self.id = msg.source
        game.players[msg.source] = msg.data
        game.clients[msg.source] = client
      when "syncSelf"
        self.player[k] = v for k, v of msg.data
        broadcast("syncPlayer", msg.data)
      when "removePowerup"
        delete game.powerups[msg.data]
        broadcast("removePowerup", msg.id)

  client.on "disconnect", ->
    broadcast("removePlayer", self.id)
    delete game.players[self.id]
    delete game.clients[self.id]

send_powerup = ->
  if Object.keys(game.powerups).length < constants.maxPowerups
    x = Math.random() * constants.universeWidth
    y = Math.random() * constants.universeHeight
    powerup = {id: next_id(), x: x, y: y}
    game.powerups[powerup.id] = powerup
    broadcast("addPowerup", powerup)
  setTimeout send_powerup, 10 + Math.random() * 10000

send_powerup()
app.listen process.env.PORT || 8081
