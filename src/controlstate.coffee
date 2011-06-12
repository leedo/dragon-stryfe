module.exports = class ControlState
  constructor: ->
    @wPressed = false
    @aPressed = false
    @dPressed = false
    @sPressed = false
    @spacePressed = false
    @target   = false # place that touches want us to get to
    @mouseDown = false
  anyPressed: () ->
    pressed = false
    # get this comprehension to work some time when I have net acceess and can view coffeescript docs
    #for key of this
    #  pressed |= this.key
    pressed = @wPressed || @aPressed || @sPressed || @dPressed || @spacePressed
    return pressed
