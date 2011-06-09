Player = require 'player'
Powerup = require 'powerup'
util = require 'util'
constants = require 'constants'

module.exports = class Universe
  constructor: (starting_name) ->
    @self
    @players = {}
    @powerups = []
    @tick_count = 0
    @starting_name = starting_name
    @is_drawing
    @draw_buf = []
    @board = document.getElementById "universe"
    @context = @board.getContext "2d"

    @connect()

  gameTick: ->
    @tick_count++
    @board.width = @board.width
    @addPowerup() if @powerups.length < constants.maxPowerups and @tick_count % constants.powerupTimer == 0
    @drawOverlay()
    @drawPowerups()
    @tickPlayer player for id, player of @players
    @syncSelf() if @tick_count % constants.syncTimer == 0

    setTimeout (=> @gameTick()), 40

  drawOverlay: ->
    @drawStats()
    @drawEnergyMeter()
    @drawPlayerList()

  addPowerup: ->
    x = Math.random() * @board.width
    y = Math.random() * @board.height
    console.log "adding powerup #{x}, #{y}"
    powerup =  new Powerup x, y
    @powerups.push powerup

  drawPowerups: ->
    powerup.draw @context for powerup in @powerups

  drawPlayerList: ->
    [x, y] = [@board.width - 100, 100]
    @context.fillStyle = "#fff"
    for id, player of @players
      @context.fillText "#{parseInt player.damage} #{player.name}", x, y
      y += 10

  drawStats: ->
    @context.fillStyle = "#fff"
    @context.fillText "x: #{parseInt @self.position.x}", 10, 10
    @context.fillText "y: #{parseInt @self.position.y}", 10, 20
    @context.fillText "angle: #{@self.position.angle}", 10, 30
    @context.fillText "speed: #{@self.speed}", 10, 40
    @context.fillText "thrust: #{@self.energy}", 10, 50
    @context.fillText "id: #{@self.id}", 10, 60
    @context.fillText "dead: #{@self.dead}", 10, 70

  syncSelf: ->
    @socket.send @self.serialized()

  tickPlayer: (player) ->
    # flip player around if he is at any walls
    if player.position.x <= 0 or player.position.x >= @board.width
      player.position.angle = 2 * Math.PI - player.position.angle
    else if  player.position.y >= @board.height or player.position.y <= 0
      player.position.angle = Math.PI - player.position.angle

    # see if this player hit any powerups
    for i, powerup of @powerups
      if powerup.contains player.position
        powerup.apply_bonus player
        @powerups.splice i, 1

    player.gameTick()
    player.tryToBreath(target) for id, target of @players
    player.draw @context

  initSelf: (state) ->
    console.log "init self with id #{state.id}"

    # just override the default with center
    state.x = @board.width / 2
    state.y = @board.height / 2
    if !@starting_name
      state.name = prompt "What is your dragon's name?"
      state.name = state.name.substr 0, 16
    else
      state.name = @starting_name

    @self = @addPlayer state

    @enableControls()
    @syncSelf()
    @gameTick()

  disableControls: ->
    @board.removeEventListener "mousedown"
    document.removeEventListener "keyup"
    document.removeEventListener "keydown"

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
    , false

    document.addEventListener "keyup", (e) =>
      switch e.keyCode
        when 87, 73
          @self.controls.wPressed = false
        when 68, 76
          @self.controls.dPressed = false
        when 65, 74
          @self.controls.aPressed = false
        when 32
          @self.controls.spacePressed = false
        when 83, 75
          @self.controls.sPressed = false
      @syncSelf()
    , false
    document.addEventListener "keydown", (e) =>
      switch e.keyCode
        when 87, 73
          @self.controls.wPressed = true
        when 68, 76
          @self.controls.dPressed = true
        when 65, 74
          @self.controls.aPressed = true
        when 32
          @self.controls.spacePressed = true
        when 83, 75
          @self.controls.sPressed = true
      @syncSelf()
    , false

  removePlayer: (id) ->
    console.log "remove player #{id}"
    delete @players[id]

  addPlayer: (state) ->
    console.log "add player #{state.id}"
    state.max_x = @board.width
    state.max_y = @board.height
    player = new Player state
    @players[player.id] = player
    return player

  addPlayers: (new_players) ->
    @addPlayer(player) for player in new_players

  syncPlayer: (state) ->
    player = @players[state.id]
    return if !player or player.id == @self.id or player.dead
    player.update state

  connect: ->
    @socket = new io.Socket window.location.hostname
    @socket.connect()
    @socket.on 'disconnect', ->
      players = {}
      @self = null
      @disableControls()
    @socket.on 'message', (msg) =>
      req = JSON.parse msg
      @[ req.action ](req.data)

  drawEnergyMeter: ->
    [x, y] = [@board.width - 30, @board.height - 10]
    for i in [0..10]
      @context.fillStyle = if i*10 <= @self.energy then "red" else "#ccc"
      @context.fillRect x, y, 20, 5
      y -= 10
