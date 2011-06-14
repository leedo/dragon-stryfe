Powerup = require("powerup").Powerup
constants = require "constants"

module.exports = class HealthBoost extends Powerup
  prepare_powerup: (opts) ->
    @img = document.getElementById("health-powerup")
    @radius = 10

  apply_bonus: (player) ->
    player.health_regen += constants.deadlyDamage / 2
