ControlState = require "controlstate"
PositionState = require "positionstate"
constants = require "constants"

# some definitions for the tweakable bits
util = require 'util'

module.exports  = class Player
  constructor: (opts) ->
    @id = opts.id
    @breathing = false
    @img = document.getElementById("dragon")

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
    if @controls.spacePressed
      @breathing = Math.PI
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
    dist = if @trail.length then util.distanceFrom(@position, @trail[0]) else 0
    if !@trail.length or dist > 4
      @trail.unshift {x: @position.x, y: @position.y, dist: dist, angle: @position.angle}
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

  drawTail: (context) ->
    context.fillStyle = "#fff"
    width = 3
    for coord in @trail
      if coord and prev
        context.save()
        context.translate coord.x, coord.y
        context.rotate -coord.angle
        context.fillRect 0, 0, width, coord.dist + 2
        context.restore()
        width -= 0.2
      prev = coord

  drawShip: (context) ->
    context.drawImage(@img, -10, 0)

  drawFire: (context) ->
    width = 8
    blocksize = 8
    rate = 1.8
    transparency = 0.1

    context.save()
    context.translate 0, -10

    for dist in [0 .. 4]
      blocks = Math.ceil(width / blocksize)
      x = -(width / 2)
      y = -(blocksize * dist)
      transparency += 0.15
      for block in [0 .. blocks]
        opacity = (parseInt(Math.random() * 10) / 10) - transparency
        context.fillStyle = "rgba(255,127,0,#{opacity})"
        context.fillRect x + (block * blocksize), y, blocksize+1, blocksize+1
      width = width * rate

    context.restore()

  drawName: (context) ->
    context.save()
    context.translate @position.x, @position.y
    context.fillStyle = "#000"
    context.fillText @name, -5, -15
    context.fillText @name, -3, -17
    context.fillStyle = "#fff"
    context.fillText @name, -4, -16
    context.restore()

  draw: (context) ->
    @drawTail context
    context.save()
    context.translate @position.x, @position.y
    context.rotate -@position.angle
    context.translate -4, -3
    @drawShip context
    @drawFire context if @breathing
    context.restore()
    @drawName(context)
