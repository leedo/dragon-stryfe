module.exports = class Animation
  constructor: (opts) ->
    @id = opts.id
    @x = opts.x || 0
    @y = opts.y || 0
    @speed = opts.speed || 0
    @angle = opts.angle || 0
    @prepare_animation(opts)

  update: (opts) ->
    @[k] = v for k, v of opts
