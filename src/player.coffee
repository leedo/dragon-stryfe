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
    @trail = []
    @update(opts)
    if opts.colors and opts.colors.length
      @body_color = opts.colors[4]
      @highlight_color = opts.colors[2]
    else
      @body_color = util.randomColor()
      @highlight_color = util.randomColor()

  serialized: ->
    data =
      body_color: @body_color
      highlight_color: @highlight_color
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
    @dead     = opts.dead     || 0  # dead if != 0, else ticks since dead
    @flash    = opts.flash    || 0 # draw a flash around the dragon this turn (player respawn, what else?)
    @body_color = opts.body_color || @body_color
    @highlight_color = opts.highlight_color || @highlight_color

  handleInput: ->
    # don't move if you're dead
    if @dead != 0
      @speed = 0
      @position.angle = Math.PI * @dead / 10.0
      @dead++
      return

    if @controls.spacePressed
      @breathing = Math.PI
    if @controls.wPressed and @speed < constants.maxSpeed
      @speed += constants.accelRate
    if @controls.sPressed and @speed > constants.minSpeed
      @speed -= constants.brakingRate
      @speed = 0 if @speed < constants.minSpeed
    if @controls.target != false
      # try and steer towards the target, slow down if it's under our turning radius
      # otherwise speed up
      toTarget = util.subtractVec(@controls.target, @position)
      angleToTarget = Math.PI + Math.atan2(toTarget.x, toTarget.y) - @position.angle
      # fix this wonky hacky shit
      if angleToTarget > Math.PI
        sign = -1
      else if angleToTarget > 0
        sign = 1
      else if angleToTarget > -Math.PI
        sign = 1
      else
        sign = -1
      turnLimit = @speed * constants.playerTurnRate
      if @thrusting()
        turnLimit *= 4
      turnAmount = util.clamp angleToTarget/sign, -turnLimit, turnLimit
      @position.angle += turnAmount
      @speed = Math.min constants.maxSpeed, constants.accelRate + @speed
      distAway = util.length toTarget
      if distAway < 10.0
        @controls.target = false

    else if @speed > constants.coastSpeed
      @speed -= constants.decelRate

    multiplier = 0
    # update our angle if a turn key is on
    # angle is increased if thrust is on
    if @controls.aPressed and !@controls.dPressed
      multiplier = if @thrusting() or @controls.sPressed then 4 else 1
    else if @controls.dPressed and !@controls.aPressed
      multiplier = if @thrusting() or @controls.sPressed then -4 else -1

    @position.angle += constants.playerTurnRate * @speed * multiplier

    # constrain angle to the range [0 .. 2*PI]
    if @position.angle > Math.PI * 2.0
       @position.angle -= Math.PI * 2.0
    if @position.angle < 0.0
       @position.angle += Math.PI * 2.0

  updateEnergy: ->
    if @thrusting()  # how can we be thrusting without any gas?
      @energy--
      @controls.wPressed = false unless @energy
    else
      @energy += constants.energyRegenRate
      @energy = Math.min(@energy, constants.maxEnergy)

  thrusting: ->
    (@controls.wPressed or @controls.target) and @energy >= 1

  gameTick: ->
    @breathing = false
    @handleInput()
    @updatePosition()
    @updateTrail()
    @updateEnergy()

  updatePosition: ->
    scale_y = Math.cos @position.angle
    scale_x = Math.sin @position.angle
    velocity_x = @speed * scale_x
    velocity_y = @speed * scale_y
    @position.x -= velocity_x
    @position.x = Math.min(constants.universeWidth, Math.max(@position.x, 0))
    @position.y -= velocity_y
    @position.y = Math.min(constants.universeHeight, Math.max(@position.y, 0))

  updateTrail: ->
    dist = if @trail.length then util.distanceFrom(@position, @trail[0]) else 0
    if !@trail.length or dist > 4
      @trail.unshift {x: @position.x, y: @position.y, dist: dist, angle: @position.angle}
      @trail.pop() if @trail.length > constants.maxTrailLength

  tryToBreath: (target) ->
    return if target.id == @id or @dead
    if util.distSquared(@position, target.position) < constants.fireDistanceSquared
      vecToPlayer = util.subtractVec(target.position, @position)
      angleToPlayer = Math.PI + Math.atan2(vecToPlayer.x, vecToPlayer.y)
      if Math.abs(angleToPlayer - @position.angle) < 0.8
        @breathing = angleToPlayer
        target.damage += Math.max(@speed, 0)

  drawTail: (context) ->
    # do we wanna draw the tail if we're dead? nope
    # but we zero out the tail at death
    width = 3
    for i, coord of @trail
      if coord and prev
        context.save()
        context.fillStyle = if i % 2 then @body_color else @highlight_color
        context.translate coord.x, coord.y
        context.rotate -coord.angle
        context.fillRect 0, 0, width, coord.dist + 2
        context.restore()
        width -= 0.2
      prev = coord

  drawShip: (context) ->
    context.drawImage(@img, -10, 0)
    orig = context.globalCompositeOperation
    context.globalCompositeOperation = "source-atop"
    context.fillStyle = @body_color
    context.fillRect(1, 0, 10, 30)
    context.fillRect(1, 1, 10, 10)
    context.fillStyle = @highlight_color
    context.fillRect(-10, 10, 12, 16)
    context.fillRect(10, 10, 12, 16)
    context.globalCompositeOperation = orig

  drawFire: (context) ->
    width = 8
    blocksize = 8
    rate = 1.8
    transparency = 0.1

    console.log context.globalCompositeOperation
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
    context.translate @position.x - 4, @position.y - 16
    context.fillStyle = "#000"
    context.fillRect -1, 2, 22, 4
    context.fillStyle = "green"
    context.fillRect 0, 3, 20, 2
    context.shadowBlur = 3
    context.shadowColor = "#000"
    context.fillStyle = "#fff"
    context.fillText @name, 0, 0

    context.restore()

  draw: (context) ->
    @drawTail context
    context.save()
    context.translate @position.x, @position.y
    context.rotate -@position.angle
    context.translate -4, -3
    # does scaling not work with bitmaps?
    #if @dead
      #scaleFactor = 1.0 - (@dead / 50.0)
      #context.scale scaleFactor scaleFactor
    if @flash > 4
      #should this be a different color?
      oldfillstyle = @context.fillstyle
      @context.fillstyle = "#ff0"
      @context.arc @position.x, @position.y, 30, 0, (2 * Math.PI), false
      @context.fill()
      @context.fillstyle = oldfillstyle
      @flash++
    else if @flash >= 4
      @flash = 0
    @drawShip context
    @drawFire context if @breathing
    context.restore()
