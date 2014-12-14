deep = (value, other) -> lodash.merge(value, other, deep)

Setter =

  defaultValue: (value, defaultValue) ->
    if value == undefined then defaultValue else value

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
