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
    for origKey, value of obj
      keys = callback(origKey)
      if keys?
        @addRecursiveProperty(obj, keys, value)
        delete obj[origKey]


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