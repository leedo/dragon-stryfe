Animation = require "animation"
util = require "util"
constants = require "constants"

exports.Powerup = class Powerup extends Animation
  prepare_animation: (opts) ->
    @radius = 10
    @rgb = [255, 255, 255]
    @prepare_powerup(opts)

  draw: (context) ->
    context.drawImage(@img, @x, @y)

  contains: (position) ->
    dist = util.distanceFrom {x: @x + @radius / 2, y: @y + @radius / 2}, position
    dist < @radius

types = {
  health: require("healthboost"),
  energy: require ("energyboost")
}

exports.createPowerup = (type, opts) -> new types[type](opts)
