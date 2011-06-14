Player = require 'player'
powerup = require 'powerup'
util = require 'util'
constants = require 'constants'

module.exports = class Universe
  constructor: (id, name, colors) ->
    @board = document.getElementById "universe"
    @last_refresh
    @player_map = {}
    @powerup_map = {}
    @tick_count = 0
    @stopped = true
    @is_mousing = false
    @context = @board.getContext "2d"

    @createSelf id, name, colors
    @refresh()
    @connect()

  startGame: ->
    @stopped = false
    @player_map[@self.id] = @self
    if document.ontouchmove == null or document.ontouchmove != undefined
      @enableTouchControls()
    else
      @enableDesktopControls()

  stopGame: ->
    @stopped = true
    @tick_count = 0
    @player_map = {}

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

  refresh: ->
    ticks = 1
    if @last_refresh
      now = (new Date()).getTime()
      diff = now - @last_refresh
      ticks = Math.floor diff / constants.tickLength

    @gameTick() for i in [1 .. ticks]

    @board.width = @board.width
    for player in @players()
      player.draw @context
      player.drawName(@context, player != @self)

    @drawPowerups()
    @drawOverlay()
    @syncSelf() unless @stopped

    @last_refresh = (new Date()).getTime()
    setTimeout (=> @refresh()), constants.tickLength

  gameTick: ->
    @tick_count++
    return if @stopped
    @tickPlayer player for id, player of @players()
    @checkDeath()

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
          @sendAction "removePowerup", id

    player.gameTick()
    player.tryToBreath(target) for id, target of @players()

  players: ->
    player for id, player of @player_map

  getPlayer: (id) ->
    @player_map[id]

  removePlayer: (id) ->
    console.log "remove player #{id}"
    delete @player_map[id]

  addPlayer: (state) ->
    console.log "add player #{state.id}", state
    player = new Player state
    @player_map[player.id] = player
    return player

  addPlayers: (new_players) ->
    @addPlayer(player) for player in new_players

  syncPlayer: (state) ->
    player = @getPlayer state.id
    return if !player or player.id == @self.id
    player[k] = v for k, v of state

  powerups: ->
    powerup for id, powerup in @powerup_map

  removePowerup: (id) ->
    delete @powerups[id]

  addPowerup: (opts) ->
    console.log "add powerup"
    @powerups[opts.id] = powerup.createPowerup(opts.type, opts)

  addPowerups: (new_powerups) ->
    @addPowerup(opts) for opts in new_powerups

  syncScore: (data) ->
    player = @getPlayer data.id
    player.kills = data.score

  drawOverlay: ->
    #@drawStats()
    @drawMeters()
    @drawPlayerList()

  drawPowerups: ->
    powerup.draw @context for id, powerup of @powerups

  drawPlayerList: ->
    [x, y] = [@board.width - 100, 15]
    @context.fillStyle = "#fff"
    players = @players().sort (a, b) -> b.kills - a.kills
    @context.font = "bold 11px sans-serif"
    @context.fillText "Score", x, y
    @context.font = "11px sans-serif"
    for player in players
      y += 12
      @context.fillText "#{parseInt player.kills} #{player.name}", x, y

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

  disableControls: ->
    @board.removeEventListener "mousedown"
    document.removeEventListener "keyup"
    document.removeEventListener "keydown"

  enableTouchControls: ->
    document.addEventListener "click", (e) => e.preventDefault()
    document.addEventListener "touchstart", (e) =>
      e.preventDefault()
      @self.controls.target = {x:e.touches[0].pageX, y:e.touches[0].pageY}
    , false
    document.addEventListener "touchmove", (e) =>
      e.preventDefault()
      @self.controls.target = {x:e.touches[0].pageX, y:e.touches[0].pageY}
    , false

  enableDesktopControls: ->
    document.addEventListener "mousedown", (e) =>
      return unless e.target == @board and not @self.controls.anyPressed()
      @self.controls.target = {x:e.clientX - @board.offsetLeft, y:e.clientY - @board.offsetTop}
      @self.controls.mousedown = true
      @is_mousing = true
    , false
    @board.addEventListener "mousemove", (e) =>
      return unless @is_mousing or (not @self.controls.anyPressed() and @self.controls.mouseDown)
      @self.controls.target = {x:e.clientX - @board.offsetLeft, y:e.clientY - @board.offsetTop}
    , false
    @board.addEventListener "mouseup", (e) =>
      @self.controls.mouseDown = false
      @is_mousing = false
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
          e.preventDefault()
        when 83, 75
          @self.controls.sPressed = true
      @syncSelf()
    , false

  syncSelf: ->
    @sendAction "syncSelf", @self.serialized()

  connect: ->
    @socket = new io.Socket window.location.hostname
    @socket.on 'connect', =>
      @sendAction "initSelf", @self.serialized true
      @startGame()
    @socket.on 'disconnect', =>
      @stopGame()
    @socket.on 'message', (msg) =>
      req = JSON.parse msg
      @[ req.action ](req.data)
    @socket.connect()

  drawMeters: ->
    [x, y] = [5, 5]
    height = 8

    @context.fillStyle = "rgba(255,255,255,0.2)"
    @context.fillRect x, y, 100, 8
    percent = @self.hpPercent()
    @context.fillStyle = if percent > .2 then "green" else "red"
    @context.fillRect x, y, percent * 100, 8

    y += height

    @context.fillStyle = "rgba(255,255,255,0.2)"
    @context.fillRect x, y, 100, 8
    @context.fillStyle = "rgb(252, 255, 0)"
    width = 100 * (@self.energy / constants.maxEnergy)
    @context.fillRect x, y, width, 8


  sendAction: (action, data) ->
    @socket.send
      source: @self.id
      action: action
      data: data

  checkDeath: ->
    # I'm the authoritative source on whether I'm dead
    # make people vote to find cheaters later?
    if @self.damage > constants.deadlyDamage or @self.dead
      if @self.dead == 0
        console.log "#{@self.name} died at tick #{@tick_count}"
        @sendAction "scorePoint", @self.last_attacker
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

