(function() {
  var Animation;
  module.exports = Animation = (function() {
    function Animation(opts) {
      this.id = opts.id;
      this.x = opts.x || 0;
      this.y = opts.y || 0;
      this.speed = opts.speed || 0;
      this.angle = opts.angle || 0;
      this.prepare_animation(opts);
    }
    Animation.prototype.update = function(opts) {
      var k, v, _results;
      _results = [];
      for (k in opts) {
        v = opts[k];
        _results.push(this[k] = v);
      }
      return _results;
    };
    return Animation;
  })();
}).call(this);
