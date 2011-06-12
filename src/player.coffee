ControlState = require "controlstate"
Animation = require "animation"
constants = require "constants"

# some definitions for the tweakable bits
util = require 'util'

breath = new Audio('breath.m4a')
screech = new Audio('screech.m4a')

module.exports = class Player extends Animation
  prepare_animation: (opts) ->
    @name = opts.name || "unknown"
    @body_color = opts.body_color
    @highlight_color = opts.highlight_color
    @controls = new ControlState() || opts.controls
    @breathing = false
    @img = document.getElementById("dragon")
    @trail = []
    @segment_dist = 0
    @energy = constants.maxEnergy
    @damage = 0
    @dead = 0
    @flash = 0
    @kills = 0
    @last_attacker = null

  serialized: (full) ->
    fields = ["id", "controls", "energy", "x", "y", "angle", "speed", "damage", "dead", "kills"]
    data = {}
    if full
      fields = fields.concat ["name", "body_color", "highlight_color"]
    for field in fields
      data[field] = @[field]
    return data

  deathTick: ->
    screech.play() if @dead == 1
    @angle = Math.PI * @dead / 10.0
    @speed = Math.max @speed - 0.5, 0
    @dead++

  handleInput: ->
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
      toTarget = util.subtractVec(@controls.target, @)
      angleToTarget = Math.PI + Math.atan2(toTarget.x, toTarget.y) - @angle
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
      @angle += turnAmount
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

    @angle += constants.playerTurnRate * @speed * multiplier

    # constrain angle to the range [0 .. 2*PI]
    if @angle > Math.PI * 2.0
       @angle -= Math.PI * 2.0
    if @angle < 0.0
       @angle += Math.PI * 2.0

  updateEnergy: ->
    if @dead
      @energy = 0
    else if @thrusting()  # how can we be thrusting without any gas?
      @energy--
      @controls.wPressed = false unless @energy
    else
      @energy += constants.energyRegenRate
      @energy = Math.min(@energy, constants.maxEnergy)

  thrusting: ->
    (@controls.wPressed or @controls.target) and @energy >= 1

  gameTick: ->
    @breathing = false

    if @dead > 0
      @deathTick()
    else
      @handleInput()

    @updateEnergy()
    @updateTrail()
    @updatePosition()

  updatePosition: ->
    scale_y = Math.cos @angle
    scale_x = Math.sin @angle
    velocity_x = @speed * scale_x
    velocity_y = @speed * scale_y
    @x -= velocity_x
    @y -= velocity_y
    @x = util.clamp @x, 0, constants.universeWidth
    @y = util.clamp @y, 0, constants.universeHeight

  updateTrail: ->
    if @dead
      @trail = []
      return
    @segment_dist += @speed
    dist = Math.abs @segment_dist
    if dist > 4
      @trail.unshift {x: @x, y: @y, dist: dist, angle: @angle}
      @trail.pop() if @trail.length > constants.maxTrailLength
      @segment_dist = 0

  tryToBreath: (target) ->
    return if target.id == @id or @dead
    if util.distSquared(@, target) < constants.fireDistanceSquared
      vecToPlayer = util.subtractVec(target, @)
      angleToPlayer = Math.PI + Math.atan2(vecToPlayer.x, vecToPlayer.y)
      if Math.abs(angleToPlayer - @angle) < 0.8
        @breathing = angleToPlayer
        target.damage += Math.max(@speed, 0)
        # set our ID as last attacker so it can be used to score
        # if it was a kill
        target.last_attacker = @id
        breath.play()

  drawTail: (context) ->
    width = 3
    for i, segment of @trail[0 .. 8]
      context.save()
      context.fillStyle = if i % 2 then @body_color else @highlight_color
      context.translate segment.x, segment.y
      context.rotate -segment.angle
      context.fillRect 0, 0, width, segment.dist + 2
      width -= 0.2
      context.restore()

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

  drawName: (context, health) ->
    context.save()
    context.translate @x - 4, @y - 16

    if health
      context.fillStyle = "#000"
      context.fillRect -1, 2, 22, 4
      percent = @damage / constants.deadlyDamage
      context.fillStyle = if percent < .8 then "green" else "red"
      context.fillRect 0, 3, 20 - 20 * percent, 2

    util.drawOutlinedText context, @name, 0, 0

    context.restore()

  draw: (context) ->
    @drawTail context
    context.save()
    context.translate @x, @y
    context.rotate -@angle
    context.translate -4, -3
    # does scaling not work with bitmaps?
    #if @dead
      #scaleFactor = 1.0 - (@dead / 50.0)
      #context.scale scaleFactor scaleFactor
    if @flash > 4
      #should this be a different color?
      oldfillstyle = @context.fillstyle
      @context.fillstyle = "#ff0"
      @context.arc @x, @y, 30, 0, (2 * Math.PI), false
      @context.fill()
      @context.fillstyle = oldfillstyle
      @flash++
    else if @flash >= 4
      @flash = 0
    @drawShip context
    @drawFire context if @breathing
    context.restore()
