Animation = require "animation"
util = require "util"
constants = require "constants"

exports.Powerup = class Powerup extends Animation
  prepare_animation: (opts) ->
    @radius = 10
    @color = "#ffff00"
    @prepare_powerup(opts)

  draw: (context) ->
    context.fillStyle = @color
    context.beginPath()
    context.arc @x, @y, 5, 0, Math.PI*2, true
    context.closePath()
    context.stroke()
    context.fill()

  contains: (position) ->
    dist = util.distanceFrom {x: @x, y: @y}, position
    dist < @radius

types = {
  health: require("healthboost"),
  energy: require ("energyboost")
}

exports.createPowerup = (type, opts) -> new types[type](opts)
