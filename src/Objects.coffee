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
    unflattened = {}
    callback ?= (key) -> key.split('.')
    for origKey, value of obj
      keys = callback(origKey)
      if keys?
        @addRecursiveProperty(unflattened, keys, value)
    unflattened

  flattenProperties: (obj) ->
    flattened = {}
    # Include properties defined with Object.defineProperty.
    propNames = if obj then Object.getOwnPropertyNames(obj) else []
    _.each propNames, (key) =>
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
    if branches.length == 0 then callback(obj)
    else _.each branches, (branch) => @traverseLeaves obj[branch], callback

  traverseValues: (obj, callback) ->
    _.each obj, (value, key) =>
      callback(value, key, obj)
      if Types.isObject(value) then @traverseValues value, callback

  inverse: (obj) ->
    result = {}
    _.each obj, (value, key) -> if value? then result[value] = key
    result

  trim: (obj) ->
    flatTrimmed = {}
    _.each @flattenProperties(obj), (value, key) ->
      unless !value? or ((Types.isObjectLiteral(value) or Types.isArray()) and _.isEmpty(value))
        flatTrimmed[key] = value
    @unflattenProperties(flatTrimmed)

  # Returns a boolean for whether the given selector object matches the given doc object.
  isSelectorMatch: (doc, selector) ->
    _.all selector, (value, field) ->
      docValue = Objects.getModifierProperty(doc, field)
      # TODO(aramk) Perform this with Mongo.
      if Types.isObject(value) and value.$exists?
        docValue? == value.$exists
      else
        # Allow undefined/null values for the comparison value.
        docValue == value or (!docValue? and !value?)
