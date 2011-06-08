express = require 'express'
io = require 'socket.io'
fs = require 'fs'
stitch = require 'stitch'

client_id = 1
app = express.createServer()
socket = io.listen app
players = []

package = stitch.createPackage
  paths: [__dirname]
app.configure -> app.use express.static "#{__dirname}/../public"
app.get "/client.js", package.createServer()
app.get "/", (req, res) -> res.redirect("/game.html")

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
