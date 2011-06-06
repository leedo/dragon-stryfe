(function() {
  exports.normalize = function(vec) {
    var length;
    length = sqrt(vec.x * vec.x + vec.y * vec.y);
    return {
      x: vec.x / length,
      y: vec.y / length
    };
  };
  exports.dot = function(a, b) {
    return a.x * b.x + a.y * b.y;
  };
}).call(this);
