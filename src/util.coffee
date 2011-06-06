# how brutally inefficient is doing this?
exports.normalize = (vec) ->
  length = sqrt(vec.x*vec.x+vec.y*vec.y)
  return {x:vec.x / length, y: vec.y / length}

exports.dot = (a, b) ->
  return a.x * b.x + a.y * b.y

