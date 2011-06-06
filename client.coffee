root = exports ? this

class ControlState
  constructor: (opts) ->
    @wPressed = opts.wPressed || 0
    @aPressed = opts.aPressed || 0
    @dPressed = opts.dPressed || 0

# some definitions for the tweakable bits
playerTurnRate = 0.05
maxThrust = 100.0
thrustRegenRate = 0.25
maxTrailLength = 15
maxSpeed = 8
accelRate = 0.4
coastSpeed = 0.4
decelRate = 0.1
fireDistanceSquared = 1600.0 # 4 or 5 dragon widths

# util functions


#world's slowest vector algebra library ahoy
root.length = (vec) ->
  return Math.sqrt(vec.x * vec.x + vec.y * vec.y)

# how brutally inefficient is doing this?
root.normalize = (vec) ->
    l = length(vec)
    return {x:vec.x / l, y: vec.y / l}

root.addVec = (a, b) ->
    return {x: a.x + b.x, y: a.y + b.y}

root.subtractVec = (a, b) ->
    return {x: a.x - b.x, y: a.y - b.y}

root.dot = (a, b) ->
    return a.x * b.x + a.y * b.y

# we're assuming the vectors are normalized for this?
# nah, do the efficient case some other place
root.angleBetween = (a, b) ->
    na = normalize(a)
    nb = normalize(b)
    return Math.acos(dot(na,nb))

root.distanceFrom = (a, b) ->
    return length(subtractVec(b, a))

root.distSquared = (a, b) ->
    xdiff = b.x - a.x
    ydiff = b.y - a.y
    return xdiff * xdiff + ydiff * ydiff


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
    @controls = opts.controls || {wPressed:false,aPressed:false,dPressed:false}
    @breathing = opts.breathing || false

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
    @trail.pop() if @trail.length > maxTrailLength

class Self extends Player
  constructor: ->
    @turn = 0
    @thrusting = false
    @thrust = maxThrust # amount of thrust remaining
    super

  handleInput: ->
    # update our angle if a turn key is on
    if @controls.aPressed == true and @controls.dPressed == false
      @angle += playerTurnRate
    else if @controls.dPressed == true and @controls.aPressed == false
      @angle -= playerTurnRate

    # update our speed if thrusting is on

    # use this again if we wanna have thrusting putter on when gas runs out
    #if @thrust and @controls.wPressed
    #   @thrusting = true
    if @thrusting and @speed < maxSpeed
      @speed += accelRate
    else if @speed > coastSpeed
      @speed -= decelRate

  gameTick: ->
    @handleInput()
    super
    if @thrusting and @thrust >= 1  # how can we be thrusting without any gas?
      @thrust--
    else
      @thrust += thrustRegenRate
      @thrust = Math.min(@thrust, maxThrust)
      @thrusting = false

  tryToBreathe: (player1, player2) ->
    console.log "called try to breathe from #{player1} to #{player2}"
    if player1 != player2 and distSquared(player1, player2) < fireDistanceSquared
        vecToPlayer = subtractVec(player2, player1)
        angleToPlayer = Math.atan2(vecToPlayer.x, vecToPlayer.y)
        if Math.abs(angleToPlayer - @angle) < 0.8
          @breathing = true



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
    #@content.fillText "breathing: #{@self.thrust}", 10, 60

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
