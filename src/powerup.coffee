util = require("util")
constants = require("constants")

module.exports = class Powerup
  constructor: (x, y) ->
    @x = x
    @y = y
    @radius = 10
    @color = "#ffff00"

  draw: (context) ->
    orig = context.globalCompositeOperation
    context.globalCompositeOperation = "destination-over"
    context.fillStyle = @color
    context.beginPath()
    context.arc @x, @y, 5, 0, Math.PI*2, true
    context.closePath()
    context.stroke()
    context.fill()
    context.globalCompositeOperation = orig

  apply_bonus: (player) ->
    player.energy = constants.maxEnergy

  contains: (position) ->
    dist = util.distanceFrom {x: @x, y: @y}, position
    dist < @radius
