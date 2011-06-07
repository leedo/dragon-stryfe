(function() {
  var PositionState;
  module.exports = PositionState = (function() {
    function PositionState(opts) {
      this.x = opts.x || 0;
      this.y = opts.y || 0;
      this.speed = opts.speed || 0;
      this.angle = opts.angle || 0;
    }
    return PositionState;
  })();
}).call(this);
