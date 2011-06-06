# util functions

# how brutally inefficient is doing this?
normalize = (vec) ->
  length = sqrt(vec.x*vec.x+vec.y*vec.y)
  return {x:vec.x / length, y: vec.y / length}

dot = (a, b) ->
  return a.x * b.x + a.y * b.y

# some definitions for the tweakable bits
playerTurnRate = 0.05
maxThrust = 100.0
thrustRegenRate = 0.25
maxTrailLength = 15
maxSpeed = 8
accelRate = 0.4
coastSpeed = 0.4
decelRate = 0.1

