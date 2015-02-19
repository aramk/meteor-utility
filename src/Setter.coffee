deep = (value, other) -> lodash.merge(value, other, deep)

Setter =

  defaultValue: (value, defaultValue) ->
    if value == undefined then defaultValue else value

  # @param {Number} value
  # @param {Number} min
  # @param {Number} max
  # @returns {Number} The given value if it falls within the given range, or either min or max if
  # it doesn't.
  range: (value, min, max) ->
    if value < min
      min
    else if value > max
      max
    else
      value

  merge: (args...) ->
    dest = args[0]
    args.shift()
    for arg in args
      lodash.merge(dest, arg)
    dest

  clone: (src) ->
    lodash.cloneDeep(src)

 # Deeply merges defaults, relying on _.merge(a,b) returning a if it isn't an object to prevent
 # source property values overriding their defined destinations.
  defaults: lodash.partialRight(lodash.merge, deep)

 # @param {*} value
 # @returns Whether the given value is not an non-empty string, null, undefined or NaN.
  isDefined: (value) -> value != '' && value? && !isNaN(value)
