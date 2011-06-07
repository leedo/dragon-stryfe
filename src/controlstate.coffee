module.exports = class ControlState
  constructor: (opts) ->
    @wPressed = opts.wPressed || 0
    @aPressed = opts.aPressed || 0
    @dPressed = opts.dPressed || 0
