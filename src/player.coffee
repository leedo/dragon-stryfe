ControlState = require "controlstate"
PositionState = require "positionstate"
constants = require "constants"

# some definitions for the tweakable bits
util = require 'util'

module.exports  = class Player
  constructor: (opts) ->
    @id = opts.id
    @breathing = false

    @max_x = opts.max_x
    @max_y = opts.max_y

    @trail = []
    @update(opts)

  serialized: ->
    data =
      controls: @controls
      position: @position
      speed: @speed
      energy: @energy
      id: @id
      name: @name
      damage: @damage

  update: (opts) ->
    @controls = opts.controls || new ControlState opts
    @position = opts.position || new PositionState opts
    @speed    = opts.speed    || 0
    @energy   = opts.energy   || constants.maxEnergy
    @name     = opts.name     || "unknown"
    @damage   = opts.damage   || 0

  handleInput: ->
    if @controls.wPressed and @speed < constants.maxSpeed
      @speed += constants.accelRate
    else if @speed > constants.coastSpeed
      @speed -= constants.decelRate

    # update our angle if a turn key is on
    if @controls.aPressed and !@controls.dPressed
      @position.angle += constants.playerTurnRate
    else if @controls.dPressed and !@controls.aPressed
      @position.angle -= constants.playerTurnRate

    # constrain angle to the range [0 .. 2*PI]
    if @position.angle > Math.PI * 2.0
       @position.angle -= Math.PI * 2.0
    if @position.angle < 0.0
       @position.angle += Math.PI * 2.0

  thrusting: ->
    @controls.wPressed and @energy >= 1

  gameTick: ->
    @breathing = false

    @handleInput()
    @updatePosition()
    @updateTrail()

    if @thrusting()  # how can we be thrusting without any gas?
      @energy--
    else
      @energy += constants.energyRegenRate
      @energy = Math.min(@energy, constants.maxEnergy)

  updatePosition: ->
    scale_y = Math.cos @position.angle
    scale_x = Math.sin @position.angle
    velocity_x = @speed * scale_x
    velocity_y = @speed * scale_y
    @position.x -= velocity_x
    @position.x = Math.min(@max_x, Math.max(@position.x, 0))
    @position.y -= velocity_y
    @position.y = Math.min(@max_y, Math.max(@position.y, 0))

  updateTrail: ->
    # stick an empty element in if no thrusting on
    @trail.unshift if @thrusting() then [@position.x, @position.y] else null
    @trail.pop() if @trail.length > constants.maxTrailLength

  # can I not pass in both players?  does it really matter?
  tryToBreath: (target) ->
    return if target.id == @id
    if util.distSquared(@position, target.position) < constants.fireDistanceSquared
      vecToPlayer = util.subtractVec(target.position, @position)
      angleToPlayer = Math.PI + Math.atan2(vecToPlayer.x, vecToPlayer.y)
      if Math.abs(angleToPlayer - @position.angle) < 0.8
        @breathing = angleToPlayer
        target.damage++

  drawTrail: (context) ->
    opacity = 0.3
    for coord in @trail
      opacity -= 0.01
      if coord
        [x, y] = coord
        context.fillStyle = "rgba(255,255,255,#{opacity})"
        context.fillRect x, y, 8, 8

  drawShip: (context) ->
    context.fillStyle = "#fff"
    context.fillRect 0, 0, 8, 8
    context.fillStyle = if @thrusting() then "red" else "rgba(255,255,255,0.5)"
    context.fillRect 0, 8, 8, 2

  drawFire: (context) ->
    context.fillStyle = "red"
    context.beginPath()
    context.moveTo(4,8)
    context.lineTo(12, -40)
    context.lineTo(-4,-40)
    context.fill()

  draw: (context) ->
    context.save()
    @drawTrail context
    context.translate @position.x, @position.y
    context.fillStyle = "#fff"
    context.fillText @name, -4, -15
    context.rotate -@position.angle
    context.translate -4, -3
    @drawFire context if @breathing
    @drawShip context
    context.restore()
