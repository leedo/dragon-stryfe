Animation = require "animation"
util = require "util"
constants = require "constants"

exports.Powerup = class Powerup extends Animation
  prepare_animation: (opts) ->
    @radius = 10
    @prepare_powerup(opts)

  draw: (context) ->
    orig = context.globalCompositeOperation
    context.globalCompositeOperation = "destination-over"
    context.drawImage(@img, @x, @y)
    context.globalCompositeOperation = orig

  contains: (position) ->
    dist = util.distanceFrom {x: @x + @radius / 2, y: @y + @radius / 2}, position
    dist < @radius

types = {
  health: require("healthboost"),
  energy: require ("energyboost")
}

exports.createPowerup = (type, opts) -> new types[type](opts)
