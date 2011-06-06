(function() {
  var ControlState;
  ControlState = (function() {
    function ControlState(opts) {
      this.wPressed = opts.wPressed || 0;
      this.aPressed = opts.aPressed || 0;
      this.dPressed = opts.dPressed || 0;
    }
    return ControlState;
  })();
}).call(this);
