module.exports = class PositionState
  constructor: (opts) ->
    @x = opts.x || 0
    @y = opts.y || 0
    @speed = opts.speed || 0
    @angle = opts.angle || 0

