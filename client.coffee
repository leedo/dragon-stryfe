class Player
  constructor: (opts) ->
    @x = opts.x || 0
    @y = opts.y || 0
    @speed = opts.speed || 0
    @angle = opts.angle || 0
    @id = opts.id
    @elem = @createShip()

  createShip: ->
    elem = document.createElement "DIV"
    label = document.createElement "SPAN"
    label.className = "label"
    label.innerHTML = @id
    elem.appendChild label
    elem.id = "player-#{@id}"
    elem.className = "player"
    elem.style.left = @x+"px"
    elem.style.top = @y+"px"
    elem

  gameTick: ->
    @elem.style.webkitTransform = "rotate(#{@angle}rad)"

    scale_y = -Math.cos @angle
    scale_x = Math.sin @angle
    velocity_x = @speed * scale_x
    velocity_y = @speed * scale_y
    @x -= velocity_x
    @y -= velocity_y

  moveTo: (x, y) ->
    @elem.style.left = x+"px"
    @elem.style.top = y+"px"

class Self extends Player
  constructor: ->
    @turn = 0
    @thrust = false
    super

  handleInput: ->
    # update our angle if a turn key is on
    if @turn != 0
      @angle += @turn * 0.05

    # update our speed if thrust is on
    if @thrust and @speed < 2
      @speed += 0.1
    else if @speed > 0.1
      @speed -= 0.025

  gameTick: ->
    @handleInput()
    super

  createShip: ->
    elem = super
    elem.className = "player self"
    elem

class Universe
  constructor: ->
    @self
    @players = {}
    @board = document.getElementById("board")
    @width = @board.scrollWidth
    @height = @board.scrollHeight
    @center = [ @width / 2, @height / 2]
    @socket = @connect()

    setInterval (=> @gameTick()), 10
    setInterval (=> @syncSelf()), 100

  coordToPos: (x, y) ->
    return [@center[0] - x, @center[1] - y]

  posToCoord: (x, y) ->
    return [x - @center[0], @center[1] - y]

  gameTick: ->
    @tickPlayer @self if @self
    for id, player of @players
      @tickPlayer player

  syncSelf: ->
    @socket.send
      x: @self.x,
      y: @self.y,
      speed: @self.speed,
      angle: @self.angle

  tickPlayer: (player) ->
    player.gameTick()
    [x, y] = @coordToPos(player.x, player.y)
    player.moveTo(x, y)

  initSelf: (state) ->
    console.log "init self with id #{state.id}"
    @self = new Self state
    @board.appendChild @self.elem
    @enableControls()

  enableControls: ->
    document.addEventListener "keyup", (e) =>
      switch e.keyCode
        when 87
          @self.thrust = false
        when 68
          @self.turn = 0
        when 65
          @self.turn = 0
    document.addEventListener "keydown", (e) =>
      switch e.keyCode
        when 87
          @self.thrust = true
        when 68
          @self.turn = 1
        when 65
          @self.turn = -1

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

  syncPlayer: (state) ->
    console.log "syncing player #{state.id}"
    player = @players[state.id]
    return unless player # don't sync our self
    player.speed = state.speed
    player.angle = state.angle
    player.x = state.x
    player.y = state.y

  connect: ->
    socket = new io.Socket "127.0.0.1"
    socket.connect()
    socket.on 'message', (msg) =>
      req = JSON.parse msg
      @[ req.action ](req.data)
    socket

document.addEventListener "DOMContentLoaded", -> universe = new Universe()
