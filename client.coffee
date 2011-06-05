class Player
  constructor: (opts) ->
    @x = opts.x || 0
    @y = opts.y || 0
    @speed = opts.speed || 0
    @angle = opts.angle || 0
    @id = opts.id
    @name = opts.name || "unknown"

  gameTick: ->
    scale_y = Math.cos @angle
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
    if @thrust and @speed < 4
      @speed += 0.2
    else if @speed > 0.2
      @speed -= 0.05

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
    @context = @board.getContext "2d"

    @is_drawing
    @draw_buf = []

    @socket = @connect()

  gameTick: ->
    @board.width = @board.width
    @context.save()
    @tickPlayer @self if @self
    @drawInfo()
    # checks to keep people in the visible area
    if  @self.x < 0  || @self.y < 0 || @self.x > @board.width || @self.y > @board.height
        @self.angle += Math.PI
    for id, player of @players
      @tickPlayer player

  drawInfo: ->
    @context.fillStyle = "#fff"
    @context.fillText "x: #{parseInt @self.x}", 10, 10
    @context.fillText "y: #{parseInt @self.y}", 10, 20
    @context.fillText "angle: #{@self.angle}", 10, 30

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
    # just override the provided 0,0 default center
    state.x = @board.width / 2
    state.y = @board.height / 2
    state.name = prompt "What is your dragon's name?"
    @self = new Self state
    @syncSelf() # sync right away to update our name
    @drawPlayer @self
    @enableControls()

    setInterval (=> @syncSelf()), 100
    setInterval (=> @gameTick()), 20

  enableControls: ->

    # capture points into @draw_buf if someone clicks
    # on their own ship
    @board.addEventListener "mousedown", (e) =>
      return unless e.target == @board
      @is_drawing = true
      @draw_buf = []
    @board.addEventListener "mousemove", (e) =>
      return unless @is_drawing
      @draw_buf.push e.clientX, e.clientY
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
          @self.turn = -1
        when 65
          @self.turn = 1

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
    socket = new io.Socket window.location.hostname
    socket.connect()
    socket.on 'message', (msg) =>
      req = JSON.parse msg
      @[ req.action ](req.data)
    socket

  drawPlayer: (player) ->
    [x, y] = [player.x, player.y]
    @context.translate x, y
    @context.fillStyle = "#fff"
    @context.fillText player.name, -4, -15
    @context.rotate -player.angle
    @context.translate -4, -3
    @context.fillStyle = "#fff"
    @context.fillRect 0, 0, 8, 8
    @context.fillStyle = "red"
    @context.fillRect 0, 8, 8, 2
    @context.restore()




document.addEventListener "DOMContentLoaded", -> universe = new Universe()
