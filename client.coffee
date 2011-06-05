class Player
  constructor: (opts) ->
    @sync = ["name", "speed", "angle", "x", "y", "trail", "thrusting"]
    @x = opts.x || 0
    @y = opts.y || 0
    @speed = opts.speed || 0
    @angle = opts.angle || 0
    @id = opts.id
    @thrusting = opts.thrusting || false
    @name = opts.name || "unknown"
    @trail = []

  serialized: ->
    data = {}
    for field in @sync
      data[field] = @[field]
    data

  gameTick: ->
    scale_y = Math.cos @angle
    scale_x = Math.sin @angle
    velocity_x = @speed * scale_x
    velocity_y = @speed * scale_y
    @x -= velocity_x
    @y -= velocity_y

  updateTrail: ->
    # stick an empty element in if no thrusting on
    @trail.unshift if @thrusting then [@x, @y] else null
    @trail.pop() if @trail.length > 15

class Self extends Player
  constructor: ->
    @turn = 0
    @thrusting = false
    @thrust = 100 # amount of thrust remaining
    super

  handleInput: ->
    # update our angle if a turn key is on
    if @turn != 0
      @angle += @turn * 0.05

    # update our speed if thrusting is on
    if @thrusting and @speed < 8
      @speed += 0.4
    else if @speed > 0.4
      @speed -= 0.1

  gameTick: ->
    @handleInput()
    super
    if @thrusting and @thrust > 0
      @thrust--
    else
      @thrust += 0.25
      @thrusting = false


class Universe
  constructor: ->
    @self
    @players = {}
    @tick_count = 0

    @board = document.getElementById "universe"
    @board.width = document.width
    @board.height = document.height
    @context = @board.getContext "2d"

    @is_drawing
    @draw_buf = []

    @connect()

  gameTick: ->
    @board.width = @board.width
    @drawInfo()
    @drawThrustMeter()
    @context.save()
    @tickPlayer @self if @self
    @tickPlayer player for id, player of @players

    # checks to keep people in the visible area
    if  @self.x < 0  || @self.y < 0 || @self.x > @board.width || @self.y > @board.height
        @self.angle += Math.PI

    # constrain angle to the range [0 .. 2*PI]
    if @self.angle > Math.PI * 2.0
       @self.angle -= Math.PI * 2.0
    if @self.angle < 0.0
       @self.angle += Math.PI * 2.0

    setTimeout (=> @gameTick()), 40

  drawInfo: ->
    @context.fillStyle = "#fff"
    @context.fillText "x: #{parseInt @self.x}", 10, 10
    @context.fillText "y: #{parseInt @self.y}", 10, 20
    @context.fillText "angle: #{@self.angle}", 10, 30
    @context.fillText "speed: #{@self.speed}", 10, 40
    @context.fillText "thrust: #{@self.thrust}", 10, 50

  syncSelf: ->
    @self.updateTrail()
    @socket.send @self.serialized()
    setTimeout (=> @syncSelf()), 100

  tickPlayer: (player) ->
    player.gameTick()
    @drawPlayer player

  initSelf: (state) ->
    console.log "init self with id #{state.id}"

    # just override the default with center
    state.x = @board.width / 2
    state.y = @board.height / 2
    state.name = prompt "What is your dragon's name?"

    @self = new Self state
    @drawPlayer @self
    @enableControls()

    @gameTick()
    @syncSelf()

  enableControls: ->
    # capture points into @draw_buf if someone clicks
    # on their own ship
    @board.addEventListener "mousedown", (e) =>
      return unless e.target == @board
      @is_drawing = true
      @draw_buf = []
    , false
    @board.addEventListener "mousemove", (e) =>
      return unless @is_drawing
      @draw_buf.push e.clientX, e.clientY
    , false
    @board.addEventListener "mouseup", (e) =>
      return unless @is_drawing
      @is_drawing = false
      console.log @draw_buf
    , false

    document.addEventListener "keyup", (e) =>
      switch e.keyCode
        when 87
          @self.thrusting = false
        when 68
          @self.turn = 0
        when 65
          @self.turn = 0
    , false
    document.addEventListener "keydown", (e) =>
      switch e.keyCode
        when 87
          @self.thrusting = true if @self.thrust
        when 68
          @self.turn = -1
        when 65
          @self.turn = 1
    , false

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
    for field in player.sync
      player[field] = state[field]

  connect: ->
    @socket = new io.Socket window.location.hostname
    @socket.connect()
    @socket.on 'message', (msg) =>
      req = JSON.parse msg
      @[ req.action ](req.data)

  drawThrustMeter: ->
    [x, y] = [@board.width - 30, @board.height - 10]
    for i in [0..10]
      @context.fillStyle = if i*10 <= @self.thrust then "red" else "#ccc"
      @context.fillRect x, y, 20, 5
      y -= 10

  drawTrail: (player) ->
    opacity = 0.3
    for coord in player.trail
      opacity -= 0.01
      if coord
        [x, y] = coord
        @context.fillStyle = "rgba(255,255,255,#{opacity})"
        @context.fillRect x, y, 8, 8

  drawPlayer: (player) ->
    @drawTrail player
    [x, y] = [player.x, player.y]
    @context.translate x, y
    @context.fillStyle = "#fff"
    @context.fillText player.name, -4, -15
    @context.rotate -player.angle
    @context.translate -4, -3
    @context.fillStyle = "#fff"
    @context.fillRect 0, 0, 8, 8
    @context.fillStyle = if player.thrusting then "red" else "rgba(255,255,255,0.5)"
    @context.fillRect 0, 8, 8, 2
    @context.restore()




document.addEventListener "DOMContentLoaded", (-> universe = new Universe()), false
