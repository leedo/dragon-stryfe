module.exports = class ControlState
  constructor: (opts) ->
    @wPressed = opts.wPressed || 0
    @aPressed = opts.aPressed || 0
    @dPressed = opts.dPressed || 0
    @sPressed = opts.sPressed || 0
    @spacePressed = opts.spacePressed || 0
    @target   = opts.target || false # place that touches want us to get to
  anyPressed: () ->
    pressed = false
    # get this comprehension to work some time when I have net acceess and can view coffeescript docs
    #for key of this
    #  pressed |= this.key
    pressed = @wPressed || @aPressed || @sPressed || @dPressed || @spacePressed
    return pressed
