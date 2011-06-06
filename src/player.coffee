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

