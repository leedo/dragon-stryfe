#world's slowest vector algebra library ahoy
exports.length = (vec) ->
  return Math.sqrt(vec.x * vec.x + vec.y * vec.y)

# how brutally inefficient is doing this?
exports.normalize = (vec) ->
    l = length(vec)
    return {x:vec.x / l, y: vec.y / l}

exports.addVec = (a, b) ->
    return {x: a.x + b.x, y: a.y + b.y}

exports.subtractVec = (a, b) ->
    return {x: a.x - b.x, y: a.y - b.y}

exports.dot = (a, b) ->
    return a.x * b.x + a.y * b.y

# we're assuming the vectors are normalized for this?
# nah, do the efficient case some other place
exports.angleBetween = (a, b) ->
    na = normalize(a)
    nb = normalize(b)
    return Math.acos(dot(na,nb))

exports.distanceFrom = (a, b) ->
    return length(subtractVec(b, a))

exports.distSquared = (a, b) ->
    xdiff = b.x - a.x
    ydiff = b.y - a.y
    return xdiff * xdiff + ydiff * ydiff
