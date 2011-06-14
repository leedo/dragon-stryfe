Powerup = require("powerup").Powerup
constants = require "constants"

module.exports = class EnergyBoost extends Powerup
  prepare_powerup: (opts) ->
    @img = document.getElementById("energy-powerup")
    @radius = 10

  draw: (context) ->
    context.save()
    console.log @x, @y
    context.translate @x + 5, @y + 5
    context.rotate -45
    orig = context.globalCompositeOperation
    context.globalCompositeOperation = "destination-over"
    context.drawImage(@img, 0, 0)
    context.globalCompositeOperation = orig
    context.restore()

  apply_bonus: (player) ->
    player.energy_regen += constants.maxEnergy / 2
