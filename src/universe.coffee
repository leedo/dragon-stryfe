Player = require 'player'
Powerup = require 'powerup'
util = require 'util'
constants = require 'constants'

module.exports = class Universe
  constructor: (id, name, colors) ->
    @players = {}
    @powerups = {}
    @tick_count = 0
    @stopped = true
    @is_touching = false
    @board = document.getElementById "universe"
    @context = @board.getContext "2d"

    @createSelf id, name, colors
    @connect()

  gameTick: ->
    return if @stopped
    @tick_count++

    # this clears the canvas
    @board.width = @board.width
    @drawPowerups()

    @tickPlayer player for id, player of @players
    @checkDeath()

    @drawOverlay()

    # sync self every tick?
    @syncSelf() #if @tick_count % constants.syncTimer == 0

    setTimeout (=> @gameTick()), 40

  drawOverlay: ->
    #@drawStats()
    @drawEnergyMeter()
    @drawHealthMeter()
    @drawPlayerList()

  addPowerups: (new_powerups) ->
    for state in new_powerups
      @powerups[state.id] = new Powerup state

  addPowerup: (opts) ->
    console.log "add powerup"
    @powerups[opts.id] = new Powerup opts

  drawPowerups: ->
    powerup.draw @context for id, powerup of @powerups

  drawPlayerList: ->
    [x, y] = [@board.width - 100, 100]
    @context.fillStyle = "#fff"
    for id, player of @players
      @context.fillText "#{parseInt player.damage} #{player.name}", x, y
      y += 10

  drawStats: ->
    @context.fillStyle = "#fff"
    @context.fillText "x: #{parseInt @self.x}", 10, 10
    @context.fillText "y: #{parseInt @self.y}", 10, 20
    @context.fillText "angle: #{@self.angle}", 10, 30
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
    totarget = util.subtractVec @self.controls.target, @self
    toTargAngle =  Math.PI + Math.atan2(totarget.x, totarget.y)
    @context.fillText "Target angle: #{toTargAngle}", 10, 110
    @context.fillText "ToTarget vectorx: #{totarget.x}", 10, 120
    @context.fillText "ToTarget vectory: #{totarget.y}", 10, 130
    @context.fillText "DistToTarget: " + util.distanceFrom(@self, @self.controls.target), 10, 140
    @context.fillText "Want to turn: " + (toTargAngle - @self.angle), 10, 150

  syncSelf: ->
    @socket.send
      source: @self.id
      action: "syncSelf"
      data: @self.serialized()

  removePowerup: (id) ->
    delete @powerups[id]

  tickPlayer: (player) ->
    # flip player around if he is at any walls
    if player.x <= 0 or player.x >= @board.width
      player.angle = 2 * Math.PI - player.angle
    else if  player.y >= @board.height or player.y <= 0
      player.angle = Math.PI - player.angle

    # see if this player hit any powerups
    for id, powerup of @powerups
      if powerup.contains player
        powerup.apply_bonus player
        @removePowerup id
        # only tell the server we hit the powerup
        if player.id == @self.id
          @socket.send {action: "removePowerup", data: id}

    player.gameTick()
    player.tryToBreath(target) for id, target of @players
    player.draw @context
    player.drawName(@context, player != @self)

  createSelf: (id, name, colors) ->
    console.log "create self with id #{id}"
    if !name
      name = prompt "What is your dragon's name?"
      name = name.substr 0, 16

    @self = new Player
      id: id
      name: name
      body_color: colors[4] || util.randomColor()
      highlight_color: colors[2] || util.randomColor()
      x: @board.width / 2
      y: @board.height / 2

  startGame: ->
    @stopped = false
    @players[@self.id] = @self
    @enableControls()
    @gameTick()

  stopGame: ->
    @stopped = true
    @tick_count = 0
    players = {}

  disableControls: ->
    @board.removeEventListener "mousedown"
    document.removeEventListener "keyup"
    document.removeEventListener "keydown"

  enableControls: ->
    @board.addEventListener "mousedown", (e) =>
      return unless e.target == @board and not @self.controls.anyPressed()
      @self.controls.target = {x:e.clientX - @board.offsetLeft, y:e.clientY - @board.offsetTop}
      @self.controls.mousedown = true
      @is_touching = true
    , false
    @board.addEventListener "mousemove", (e) =>
      return unless @is_touching or (not @self.controls.anyPressed() and @self.controls.mouseDown)
      @self.controls.target = {x:e.clientX - @board.offsetLeft, y:e.clientY - @board.offsetTop}
    , false
    @board.addEventListener "mouseup", (e) =>
      @self.controls.mouseDown = false
      return unless @is_touching
      #@self.controls.target = {x:e.clientX - @board.offsetLeft, y:e.clientY - @board.offsetTop}
      @is_touching = false
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
    console.log "add player #{state.id}", state
    player = new Player state
    @players[player.id] = player
    return player

  addPlayers: (new_players) ->
    @addPlayer(player) for player in new_players

  syncPlayer: (state) ->
    player = @players[state.id]
    return if !player or player.id == @self.id
    player[k] = v for k, v of state

  connect: ->
    @socket = new io.Socket window.location.hostname
    @socket.on 'connect', =>
      @socket.send
        source: @self.id
        action: "initSelf"
        data: @self.serialized true
      @startGame()
    @socket.on 'disconnect', =>
      @stopGame()
    @socket.on 'message', (msg) =>
      req = JSON.parse msg
      @[ req.action ](req.data)
    @socket.connect()

  drawEnergyMeter: ->
    [x, y] = [10, 35]
    util.drawOutlinedText @context, "Energy", x, y
    y += 3
    @context.fillStyle = "rgba(255,255,255,0.2)"
    @context.fillRect x, y, 100, 5
    @context.fillStyle = "yellow"
    width = 100 * (@self.energy / constants.maxEnergy)
    @context.fillRect x, y, width, 5

  drawHealthMeter: ->
    [x, y] = [10, 15]
    util.drawOutlinedText @context, "Health", x, y
    y += 3
    @context.fillStyle = "rgba(255,255,255,0.2)"
    @context.fillRect x, y, 100, 5
    percent = @self.damage / constants.deadlyDamage
    @context.fillStyle = if percent < .8 then "green" else "red"
    @context.fillRect x, y, 100 - 100 * percent, 5

  checkDeath: ->
    # I'm the authoritative source on whether I'm dead
    # make people vote to find cheaters later?
    if @self.damage > constants.deadlyDamage or @self.dead
      if @self.dead == 0
        console.log "#{@self.name} died at tick #{@tick_count}"
        @self.dead = 1
      else if @self.dead >= constants.deathAnimationTime
        @self.damage = 0
        @self.dead = 0
        @self.x = Math.random() * constants.universeWidth
        @self.y = Math.random() * constants.universeHeight
        @self.flash = 1
        @self.energy = constants.maxEnergy
        # hacky...  should draw this in the dragon drawing routine?
        # update some kinda scoreboard?

