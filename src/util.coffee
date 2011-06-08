#world's slowest vector algebra library ahoy
length = (vec) ->
  Math.sqrt(vec.x * vec.x + vec.y * vec.y)

# how brutally inefficient is doing this?
normalize = (vec) ->
  l = length(vec)
  {x:vec.x / l, y: vec.y / l}

addVec = (a, b) ->
  {x: a.x + b.x, y: a.y + b.y}

subtractVec = (a, b) ->
  {x: a.x - b.x, y: a.y - b.y}

dot = (a, b) ->
  a.x * b.x + a.y * b.y

# we're assuming the vectors are normalized for this?
# nah, do the efficient case some other place
angleBetween = (a, b) ->
  na = normalize(a)
  nb = normalize(b)
  Math.acos(dot(na,nb))

distanceFrom = (a, b) ->
  length(subtractVec(b, a))

distSquared = (a, b) ->
  xdiff = b.x - a.x
  ydiff = b.y - a.y
  xdiff * xdiff + ydiff * ydiff

module.exports = {
  length: length
  normalize: normalize
  addVec: addVec
  subtractVec: subtractVec
  dot: dot
  angleBetween: angleBetween
  distanceFrom: distanceFrom
  distSquared: distSquared
}
