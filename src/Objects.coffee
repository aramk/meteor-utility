Objects =

  # Adds the given keys recursively, where each index in the array is a property to a separate
  # object. The final key is used to set the given value.
  addRecursiveProperty: (obj, keys, value) ->
    if keys.length == 0
      return obj
    currObj = obj
    lastKey = keys.pop()
    for key in keys
      currObj = currObj[key] ?= {}
    currObj[lastKey] = value
    obj

  # The given callback must return an array of keys for each key in the object. These keys are then
  # used to recursively redefine the properties, storing the original values.
  unflattenProperties: (obj, callback) ->
    callback ?= (key) -> key.split('.')
    for origKey, value of obj
      keys = callback(origKey)
      if keys?
        delete obj[origKey]
        @addRecursiveProperty(obj, keys, value)
    obj

  flattenProperties: (obj) ->
    flattened = {}
    # Include properties defined with Object.defineProperty.
    _.each Object.getOwnPropertyNames(obj), (key) =>
      value = obj[key]
      if Types.isObjectLiteral(value)
        _.each @flattenProperties(value), (flatValue, flatKey) ->
          flattened[key + '.' + flatKey] = flatValue
      else
        flattened[key] = value
    flattened

  getModifierProperty: (obj, property) ->
    target = obj
    segments = property.split('.')
    unless segments.length > 0
      return undefined
    for key in segments
      target = target[key]
      unless target?
        break
    target

  setModifierProperty: (obj, property, value) ->
    segments = property.split('.')
    unless segments.length > 0
      return false
    lastSegment = segments.pop()
    target = obj
    for key in segments
      target = target[key] ?= {}
    target[lastSegment] = value
    true

  # Visits all object leaves in the given object.
  traverseLeaves: (obj, callback) ->
    branches = []
    _.each obj, (value, key) ->
      if Types.isObject(value)
        branches.push(key)
    if branches.length == 0
      callback(obj)
    else
      _.each branches, (branch) =>
        @traverseLeaves(obj[branch])

  traverseValues: (obj, callback) ->
    _.each obj, (value, key) =>
      callback(value, key)
      if Types.isObject(value)
        @traverseValues(value, callback)

  inverse: (obj) ->
    result = {}
    _.each obj, (value, key) -> if value? then result[value] = key
    result
