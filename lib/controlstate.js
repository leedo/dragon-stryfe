(function() {
  var ControlState;
  module.exports = ControlState = (function() {
    function ControlState() {
      this.wPressed = false;
      this.aPressed = false;
      this.dPressed = false;
      this.sPressed = false;
      this.spacePressed = false;
      this.target = false;
      this.mouseDown = false;
    }
    ControlState.prototype.anyPressed = function() {
      var pressed;
      pressed = false;
      pressed = this.wPressed || this.aPressed || this.sPressed || this.dPressed || this.spacePressed;
      return pressed;
    };
    return ControlState;
  })();
}).call(this);
