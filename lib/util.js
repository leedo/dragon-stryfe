(function() {
  var addVec, angleBetween, clamp, distSquared, distanceFrom, dot, frontBack, leftRight, length, normalize, subtractVec;
  length = function(vec) {
    return Math.sqrt(vec.x * vec.x + vec.y * vec.y);
  };
  normalize = function(vec) {
    var l;
    l = length(vec);
    return {
      x: vec.x / l,
      y: vec.y / l
    };
  };
  addVec = function(a, b) {
    return {
      x: a.x + b.x,
      y: a.y + b.y
    };
  };
  subtractVec = function(a, b) {
    return {
      x: a.x - b.x,
      y: a.y - b.y
    };
  };
  dot = function(a, b) {
    return a.x * b.x + a.y * b.y;
  };
  angleBetween = function(a, b) {
    var na, nb;
    na = normalize(a);
    nb = normalize(b);
    return Math.acos(dot(na, nb));
  };
  distanceFrom = function(a, b) {
    return length(subtractVec(b, a));
  };
  distSquared = function(a, b) {
    var xdiff, ydiff;
    xdiff = b.x - a.x;
    ydiff = b.y - a.y;
    return xdiff * xdiff + ydiff * ydiff;
  };
  clamp = function(x, minval, maxval) {
    return Math.min(maxval, Math.max(x, minval));
  };
  leftRight = function(a, b) {
    return a.x * b.y - a.y * b.x;
  };
  frontBack = function(a, b) {
    return a.x * b.x + a.y * b.y;
  };
  module.exports = {
    length: length,
    normalize: normalize,
    addVec: addVec,
    subtractVec: subtractVec,
    dot: dot,
    angleBetween: angleBetween,
    distanceFrom: distanceFrom,
    distSquared: distSquared,
    clamp: clamp,
    leftRight: leftRight,
    frontBack: frontBack
  };
}).call(this);
