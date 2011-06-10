Player = require 'player'
Powerup = require 'powerup'
util = require 'util'
constants = require 'constants'

module.exports = class Universe
  constructor: (starting_name, colors) ->
    @self
    @players = {}
    @powerups = []
    @tick_count = 0
    @starting_name = starting_name
    @colors = colors
    @is_drawing
    @draw_buf = []
    @board = document.getElementById "universe"
    @context = @board.getContext "2d"

    @connect()

  gameTick: ->
    @tick_count++
    @board.width = @board.width
    @addPowerup() if @powerups.length < constants.maxPowerups and @tick_count % constants.powerupTimer == 0
    @tickPlayer player for id, player of @players

    @drawOverlay()
    @drawPowerups()
    # sync self every tick?
    @syncSelf() # if @tick_count % constants.syncTimer == 0
    @handleDeath()

    setTimeout (=> @gameTick()), 40

  drawOverlay: ->
    #@drawStats()
    @drawEnergyMeter()
    @drawHealthMeter()
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
    @context.fillText "pressn: #{@self.controls.anyPressed()}", 10, 80
    if @self.controls.target
      @context.fillText "targetx: #{@self.controls.target.x}", 10, 90
      @context.fillText "targetx: #{@self.controls.target.y}", 10, 100
    else
      @context.fillText "No touch target!", 10, 90
      @context.fillText "", 10, 100  # just to simplify further prints
    totarget = util.subtractVec @self.controls.target, @self.position
    toTargAngle =  Math.PI + Math.atan2(totarget.x, totarget.y)
    @context.fillText "Target angle: #{toTargAngle}", 10, 110
    @context.fillText "ToTarget vectorx: #{totarget.x}", 10, 120
    @context.fillText "ToTarget vectory: #{totarget.y}", 10, 130
    @context.fillText "DistToTarget: " + util.distanceFrom(@self.position, @self.controls.target), 10, 140
    @context.fillText "Want to turn: " + (toTargAngle - @self.position.angle), 10, 150

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
    player.drawName(@context) if player != @self

  initSelf: (state) ->
    console.log "init self with id #{state.id}"

    # just override the default with center
    state.x = @board.width / 2
    state.y = @board.height / 2
    state.colors = @colors
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
    # capture points into @draw_buf on touch
    @board.addEventListener "mousedown", (e) =>
      return unless e.target == @board and not @self.controls.anyPressed()
      @self.controls.target = {x:e.clientX - @board.offsetLeft, y:e.clientY - @board.offsetTop}
      @self.controls.mousedown = true
      @is_drawing = true

      @draw_buf = []
    , false
    @board.addEventListener "mousemove", (e) =>
      return unless @is_drawing or (not @self.controls.anyPressed() and @self.controls.mouseDown)
      @self.controls.target = {x:e.clientX - @board.offsetLeft, y:e.clientY - @board.offsetTop}
      @draw_buf.push e.clientX, e.clientY
    , false
    @board.addEventListener "mouseup", (e) =>
      @self.controls.mouseDown = false
      return unless @is_drawing
      #@self.controls.target = {x:e.clientX - @board.offsetLeft, y:e.clientY - @board.offsetTop}
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
      @self.controls.target = false
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
    [x, y] = [10, 20]
    @context.fillStyle = "rgba(255,255,255,0.2)"
    @context.fillRect x, y, 100, 5
    @context.fillStyle = "yellow"
    width = 100 * (@self.energy / constants.maxEnergy)
    @context.fillRect x, y, width, 5

  drawHealthMeter: ->
    [x, y] = [10, 10]
    @context.fillStyle = "rgba(255,255,255,0.2)"
    @context.fillRect x, y, 100, 5
    @context.fillStyle = "red"
    width = 100 - (@self.damage / constants.deadlyDamage)
    @context.fillRect x, y, width, 5

  handleDeath: ->
    # I'm the authoritative source on whether I'm dead
    # make people vote to find cheaters later?
    if @self.damage > constants.deadlyDamage or @self.dead
      @self.dead++
      if @self.dead == 1
        console.log "#{@self.name} died at tick #{@tick_count}"
        @self.damage = "dead"
        @self.trail = []
      else if @self.dead >= constants.deathAnimationTime
        @self.damage = 0
        @self.dead = 0
        @self.position.x = Math.random() * constants.universeWidth
        @self.position.y = Math.random() * constants.universeHeight
        @self.flash = 1
        # hacky...  should draw this in the dragon drawing routine?
        # update some kinda scoreboard?

