(function() {
  var accelRate, coastSpeed, decelRate, dot, maxSpeed, maxThrust, maxTrailLength, normalize, playerTurnRate, thrustRegenRate;
  normalize = function(vec) {
    var length;
    length = sqrt(vec.x * vec.x + vec.y * vec.y);
    return {
      x: vec.x / length,
      y: vec.y / length
    };
  };
  dot = function(a, b) {
    return a.x * b.x + a.y * b.y;
  };
  playerTurnRate = 0.05;
  maxThrust = 100.0;
  thrustRegenRate = 0.25;
  maxTrailLength = 15;
  maxSpeed = 8;
  accelRate = 0.4;
  coastSpeed = 0.4;
  decelRate = 0.1;
}).call(this);
