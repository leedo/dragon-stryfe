class Player
  constructor: (opts) ->
    @x = opts.x || 0
    @y = opts.y || 0
    @id = opts.id
    @elem = @createShip()

  createShip: ->
    elem = document.createElement "DIV"
    elem.id = "player-#{@id}"
    elem.className = "player"
    elem.style.left = @x+"px"
    elem.style.top = @y+"px"
    elem

  moveShip: (x, y) ->
    @x = x
    @y = y
    @elem.style.left = x+"px"
    @elem.style.top = y+"px"

class Self extends Player
  createShip: ->
    elem = super
    elem.className = "player self"
    elem

class Universe
  constructor: ->
    @self
    @players = {}
    @board = document.getElementById("board")
    @socket = @connect()

    document.addEventListener "keypress", (e) =>
      switch e.keyCode
        when 119
          @self.moveShip @self.x, @self.y - 3
        when 115
          @self.moveShip @self.x, @self.y + 3
        when 97
          @self.moveShip @self.x - 3, @self.y
        when 100
          @self.moveShip @self.x + 3, @self.y

      @socket.send
        x: @self.x,
        y: @self.y

  initSelf: (state) ->
    console.log "init self with id #{state.id}"
    @self = new Self state
    @board.appendChild @self.elem

  removePlayer: (id) ->
    console.log "remove player #{id}"
    player = @players[id]
    if player
      elem = player.elem
      elem.parentNode.removeChild elem
    delete @players[id]

  addPlayer: (state) ->
    console.log "add player #{state.id}"
    player = new Player(state)
    @board.appendChild player.elem
    @players[player.id] = player

  addPlayers: (new_players) ->
    @addPlayer(player) for player in new_players

  updatePlayer: (state) ->
    console.log "update player #{state.id}"
    player = @players[state.id]
    return unless player
    player.moveShip state.x, state.y

  connect: ->
    socket = new io.Socket "127.0.0.1"
    socket.connect()
    socket.on 'message', (msg) =>
      req = JSON.parse msg
      @[ req.action ](req.data)
    socket

document.addEventListener "DOMContentLoaded", -> universe = new Universe()
