Powerup = require("powerup").Powerup
constants = require "constants"

module.exports = class HealthBoost extends Powerup
  prepare_powerup: (opts) ->
    @radius = 10
    @color = "green"

  apply_bonus: (player) ->
    player.health_regen += constants.deadlyDamage / 2
