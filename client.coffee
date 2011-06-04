class Player
  constructor: (opts) ->
    @x = opts.x || 0
    @y = opts.y || 0
    @speed = opts.speed || 0
    @angle = opts.angle || 0
    @id = opts.id
    @name = opts.name || "unknown"

  gameTick: ->
    scale_y = -Math.cos @angle
    scale_x = Math.sin @angle
    velocity_x = @speed * scale_x
    velocity_y = @speed * scale_y
    @x -= velocity_x
    @y -= velocity_y

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

class Universe
  constructor: ->
    @self
    @players = {}

    @board = document.getElementById "universe"
    @board.width = document.width
    @board.height = document.height
    @center = [ @board.width / 2, @board.height / 2]
    @context = @board.getContext "2d"

    @is_drawing
    @draw_buf = []

    @socket = @connect()

    setInterval (=> @gameTick()), 10

  coordToPos: (x, y) ->
    return [@center[0] - x, @center[1] - y]

  gameTick: ->
    @board.width = @board.width
    @tickPlayer @self if @self
    for id, player of @players
      @tickPlayer player

  syncSelf: ->
    @socket.send
      x: @self.x,
      y: @self.y,
      speed: @self.speed,
      angle: @self.angle,
      name: @self.name

  tickPlayer: (player) ->
    player.gameTick()
    @drawPlayer player

  initSelf: (state) ->
    console.log "init self with id #{state.id}"
    state.name = prompt "What is your dragon's name?"
    @self = new Self state
    @syncSelf() # sync right away to update our name
    @drawPlayer @self
    @enableControls()
    setInterval (=> @syncSelf()), 100

  enableControls: ->

    # capture points into @draw_buf if someone clicks
    # on their own ship
    @board.addEventListener "mousedown", (e) =>
      return unless e.target == @board
      @is_drawing = true
      @draw_buf = []
    @board.addEventListener "mousemove", (e) =>
      return unless @is_drawing
      @draw_buf.push @coordToPos(e.clientX, e.clientY)
    @board.addEventListener "mouseup", (e) =>
      return unless @is_drawing
      @is_drawing = false
      console.log @draw_buf

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
    delete @players[id]

  addPlayer: (state) ->
    console.log "add player #{state.id}"
    player = new Player(state)
    @drawPlayer player
    @players[player.id] = player

  addPlayers: (new_players) ->
    @addPlayer(player) for player in new_players

  syncPlayer: (state) ->
    player = @players[state.id]
    return unless player # don't sync our self
    player.speed = state.speed
    player.angle = state.angle
    player.x = state.x
    player.y = state.y
    player.name = state.name

  connect: ->
    socket = new io.Socket "127.0.0.1"
    socket.connect()
    socket.on 'message', (msg) =>
      req = JSON.parse msg
      @[ req.action ](req.data)
    socket

  drawPlayer: (player) ->
    [x, y] = @coordToPos player.x, player.y


    @context.save()
    @context.translate x, y
    @context.translate -4, -3
    @context.fillStyle = "#fff"
    @context.fillText player.name, -4, -15
    @context.rotate player.angle
    @context.fillStyle = "#fff"
    @context.fillRect -4, -3, 8, 8
    @context.fillStyle = "red"
    @context.fillRect -4, 5, 8, 2
    @context.restore()

document.addEventListener "DOMContentLoaded", -> universe = new Universe()
