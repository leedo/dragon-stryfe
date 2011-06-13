Powerup = require("powerup").Powerup
constants = require "constants"

module.exports = class EnergyBoost extends Powerup
  prepare_powerup: (opts) ->
    @radius = 10
    @color = "#ffff00"

  apply_bonus: (player) ->
    player.energy_regen += constants.maxEnergy / 2
