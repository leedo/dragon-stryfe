express = require 'express'
io = require 'socket.io'
fs = require 'fs'
stitch = require 'stitch'
util = require './util.js'
constants = require './constants.js'
OAuth = require('oauth').OAuth
stream = require 'stream'

redis = try
  redis = require('redis').createClient()
  redis.on "error", (e) -> redis = null
catch e
  console.log "no redis available, so persistent scores won't be kept"

app = express.createServer()
socket = io.listen app
package = stitch.createPackage paths: [__dirname]

object_id = 1
next_id = -> object_id++

games = []

powerup_types = ["health", "energy"]
random_powerup_type = ->
  i = Math.floor Math.random() * powerup_types.length
  powerup_types[i]

send_powerup = (game) ->
  cb = ->
    if Object.keys(game.powerups).length < constants.maxPowerups
      x = Math.random() * constants.universeWidth
      y = Math.random() * constants.universeHeight
      x = util.clamp x, 10, constants.universeWidth - 10
      y = util.clamp y, 10, constants.universeHeight - 10
      powerup = {id: next_id(), x: x, y: y, type: random_powerup_type()}
      game.powerups[powerup.id] = powerup
      broadcast(game, "addPowerup", powerup)
    setTimeout cb, Math.random() * 5000


addGame = (logname) ->
  newgame = {
    clients: {}
    players: []
    powerups: {}
    authed: {}
    log: if constants.fullLogs then fs.createWriteStream(logname, {encoding:'utf8'}) else {}
    }
  games.push newgame
  setTimeout send_powerup(newgame), Math.random() * 5000
  return newgame


openGame = () ->
  players = 0
  gamecount = 0
  for game in games
    gamecount++
    playercount = 0
    for p in game.players
      if p
        playercount++
    if playercount < constants.maxPlayers
      console.log "Found a spot in game #" + (gamecount - 1) + " which had " + playercount + " players"
      return game
    players += playercount

  # no open games, make a new one
  console.log "Passed " + players + " concurrent players in " + gamecount + " games, adding new game"
  logname = constants.logPrefix + "game" + gamecount + ".log"
  return addGame(logname)

# no real harm in keeping around the empty games, so no game delete function
# maybe add something to mere two games' sets of players later?

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

  # keep track of users that have authed against twitter
  # so we can use them in the high score board
  for game in games
    game.authed[req.session.client_id] = true if req.session.screen_name

  res.render "game", {
    screen_name: req.session.screen_name || "",
    colors: req.session.colors || [],
    client_id: req.session.client_id
  }

app.get "/scoreboard", (req, res) ->
  sendScores = (scores) ->
    res.partial "scoreboard", {scores: scores}

  return sendScores [] unless redis

  redis.keys "ds-*", (err, keys) ->
    return sendScores [] if err or !keys.length
    redis.mget keys, (err, vals) ->
      return sendScores [] if err or !vals.length
      data = []
      data.push {name: keys[i].replace(/^ds-/,""), score: val} for i, val of vals
      console.log data
      sendScores data.sort (a, b) -> b.score - a.score


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

broadcast = (game, action, data) ->
  body = JSON.stringify {action: action, data: data}
  client.send body for id, client of game.clients
  if constants.fullLogs
    game.log.write body

send = (client, action, data) ->
  body = JSON.stringify {action: action, data: data}
  client.send body

socket.on "connection", (client) ->
  self = {client: client}

  game = openGame()

  # send existing players to new player
  send(client, "addPlayers", player for id, player of game.players)
  send(client, "addPowerups", powerup for id, powerup of game.powerups)

  client.on "message", (msg) ->

    # a socket could theoretically make multiple users since we don't
    # do any sort of check for that here
    if msg.action == "initSelf"
      broadcast(game, "addPlayer", msg.data)
      self.player = msg.data
      self.id = msg.source
      game.players[msg.source] = msg.data
      game.clients[msg.source] = client
      return

    # bail out unless this socket has set up a user
    # and the message's id matches this socket's id
    return unless self.player and msg.source == self.id

    # we have a valid user so process commands here
    switch msg.action
      when "syncSelf"
        self.player[k] = v for k, v of msg.data
        broadcast(game, "syncPlayer", msg.data)
      when "removePowerup"
        delete game.powerups[msg.data]
        broadcast(game, "removePowerup", msg.id)
      when "scorePoint"
        player = game.players[msg.data]
        return unless player
        player.kills++
        redis.incr "ds-#{player.name}" if redis and game.authed[player.id]
        broadcast(game, "syncScore", {id: player.id, score: player.kills})

  client.on "disconnect", ->
    broadcast(game, "removePlayer", self.id)
    delete game.players[self.id]
    delete game.clients[self.id]


app.listen process.env.PORT || 8081
