(function() {
  var ControlState;
  module.exports = ControlState = (function() {
    function ControlState(opts) {
      this.wPressed = opts.wPressed || 0;
      this.aPressed = opts.aPressed || 0;
      this.dPressed = opts.dPressed || 0;
      this.sPressed = opts.sPressed || 0;
      this.spacePressed = opts.spacePressed || 0;
      this.target = opts.target || false;
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
