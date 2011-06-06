players = require 'player'
util = require 'util'

exports.bang = -> new Universe()

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

    @self.breathing = false
    @self.tryToBreathe(@self, player) for id, player of @players

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

    @self = players.createSelf state
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
          @self.controls.wPressed = false
        when 68
          @self.controls.dPressed = false
        when 65
          @self.controls.aPressed = false
    , false
    document.addEventListener "keydown", (e) =>
      switch e.keyCode
        when 87
          @self.thrusting = true if @self.thrust
          @self.controls.wPressed = true
        when 68
          @self.controls.dPressed = true
        when 65
          @self.controls.aPressed = true
    , false

  removePlayer: (id) ->
    console.log "remove player #{id}"
    delete @players[id]

  addPlayer: (state) ->
    console.log "add player #{state.id}"
    player = players.createPlayer state
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
    @context.save()
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
    if player.breathing
      @context.fillStyle = "red"
      @context.beginPath()
      @context.moveTo(4,8)
      @context.lineTo(12, -40)
      @context.lineTo(-4,-40)
      @context.fill()
    @context.restore()

window.Universe = Universe
