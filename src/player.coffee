exports.createPlayer = (opts) -> new Player opts
exports.createSelf = (opts) -> new Self opts

# some definitions for the tweakable bits
playerTurnRate = 0.05
util = require 'util'

maxThrust = 100.0
thrustRegenRate = 0.25
maxTrailLength = 15
maxSpeed = 8
accelRate = 0.4
coastSpeed = 0.4
decelRate = 0.1
fireDistanceSquared = 1600.0 # 4 or 5 dragon widths


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

  # can I not pass in both players?  does it really matter?
  tryToBreathe: (player1, player2) ->
    #console.log "called try to breathe from #{player1} to #{player2}"
    if player1 != player2 and util.distSquared(player1, player2) < fireDistanceSquared
        vecToPlayer = util.subtractVec(player2, player1)
        angleToPlayer = Math.atan2(vecToPlayer.x, vecToPlayer.y)
        if Math.abs(angleToPlayer - player1.angle) < 0.8
          player1.breathing = true

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

