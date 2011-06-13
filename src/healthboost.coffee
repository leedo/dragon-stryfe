Powerup = require("powerup").Powerup
constants = require "constants"

module.exports = class HealthBoost extends Powerup
  prepare_powerup: (opts) ->
    @radius = 8
    @color = "green"

  apply_bonus: (player) ->
    player.damage -= constants.deadlyDamage / 4
    player.damage = Math.max 0, player.damage
