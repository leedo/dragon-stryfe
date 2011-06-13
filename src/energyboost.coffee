Powerup = require("powerup").Powerup
constants = require "constants"

module.exports = class EnergyBoost extends Powerup
  prepare_powerup: (opts) ->
    @img = document.getElementById("energy-powerup")
    @radius = 10
    @rgb = [255, 255, 0]

  apply_bonus: (player) ->
    player.energy_regen += constants.maxEnergy / 2
