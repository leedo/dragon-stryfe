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
    @dead     = opts.dead     || 0  # dead if != 0, else ticks since dead
    @flash    = opts.flash    || 0 # draw a flash around the dragon this turn (player respawn, what else?)

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

  updateEnergy: ->
    if @thrusting()  # how can we be thrusting without any gas?
      @energy--
    else
      @energy += constants.energyRegenRate
      @energy = Math.min(@energy, constants.maxEnergy)

  thrusting: ->
    @controls.wPressed and @energy >= 1

  handleDamage: ->
    # I'm the authoritative source on whether I'm dead
    # make people vote to find cheaters later?
    if @damage > constants.deadlyDamage or @dead
      @dead++
      if @dead == 1
        console.log "#{@self.name} died at tick #{@tick_count}"
        @damage = "dead"
        @trail = []
      else if @dead >= constants.deathAnimationTime
        @damage = 0
        @dead = 0
        @position.x = Math.random() * constants.universeWidth
        @position.y = Math.random() * constants.universeHeight
        @flash = 1
        # hacky...  should draw this in the dragon drawing routine?
        # update some kinda scoreboard?

  gameTick: ->
    @handleDamage()
    return if @dead

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
        target.damage++

  drawTail: (context) ->
    # do we wanna draw the tail if we're dead? nope
    # but we zero out the tail at death
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
    # does scaling not work with bitmaps?
    #if @dead
      #scaleFactor = 1.0 - (@dead / 50.0)
      #context.scale scaleFactor scaleFactor
    if @flash > 4
      #should this be a different color?
      oldfillstyle = @context.fillstyle
      @context.fillstyle = "#ff0"
      @context.arc @self.position.x, @self.position.y, 30, 0, (2 * Math.PI), false
      @context.fill()
      @context.fillstyle = oldfillstyle
      @flash++
    else if @flash >= 4
      @flash = 0
    @drawShip context
    @drawFire context if @breathing
    context.restore()
    @drawName(context)
