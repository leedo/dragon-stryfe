(function() {
  exports.length = function(vec) {
    return Math.sqrt(vec.x * vec.x + vec.y * vec.y);
  };
  exports.normalize = function(vec) {
    var l;
    l = length(vec);
    return {
      x: vec.x / l,
      y: vec.y / l
    };
  };
  exports.addVec = function(a, b) {
    return {
      x: a.x + b.x,
      y: a.y + b.y
    };
  };
  exports.subtractVec = function(a, b) {
    return {
      x: a.x - b.x,
      y: a.y - b.y
    };
  };
  exports.dot = function(a, b) {
    return a.x * b.x + a.y * b.y;
  };
  exports.angleBetween = function(a, b) {
    var na, nb;
    na = normalize(a);
    nb = normalize(b);
    return Math.acos(dot(na, nb));
  };
  exports.distanceFrom = function(a, b) {
    return length(subtractVec(b, a));
  };
  exports.distSquared = function(a, b) {
    var xdiff, ydiff;
    xdiff = b.x - a.x;
    ydiff = b.y - a.y;
    return xdiff * xdiff + ydiff * ydiff;
  };
}).call(this);
