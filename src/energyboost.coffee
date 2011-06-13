Powerup = require("powerup").Powerup
constants = require "constants"

module.exports = class EnergyBoost extends Powerup
  prepare_powerup: (opts) ->
    @radius = 10
    @color = "#ffff00"

  apply_bonus: (player) ->
    player.energy += constants.maxEnergy / 4
    player.energy = Math.max constants.maxEnergy, player.energy
