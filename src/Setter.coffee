deep = (value, other) -> lodash.merge(value, other, deep)
getLodashDefaults = _.once -> lodash.partialRight(lodash.merge, deep)

Setter =

  defaultValue: (value, defaultValue) ->
    if value == undefined then defaultValue else value

  # @param {Number} value
  # @param {Number} min
  # @param {Number} max
  # @returns {Number} The given value if it falls within the given range, or either min or max if
  #     it doesn't.
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

  clone: (src, args) ->
    if args?.shallow == true
      lodash.clone(src)
    else
      lodash.cloneDeep(src)

  # @param {Object} object
  # @param {Object} [defaults]
  # @returns {Object} The object argument. If defaults is defined it is deeply merged.
  # NOTE: Relying on _.merge(A,B) returning A if it isn't an object to prevent
  # source property values overriding their defined destinations.
  defaults: (obj, defaults) ->
    # Ensure the object is defined and default to an empty object to prevent returning undefined.
    obj ?= {}
    getLodashDefaults().call(lodash, obj, defaults)

  # @param {*} value
  # @returns Whether the given value is not an non-empty string, null, undefined or NaN.
  isDefined: (value) -> value != '' && value? && (!Types.isNumber(value) || !isNaN(value))
