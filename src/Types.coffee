Types =

  getTypeOf: (object) ->
    Object.prototype.toString.call(object).slice(8, -1)

  isType: (object, type) ->
    if object? then this.getTypeOf(object) == type else object == type

  isObject: (object) -> object && typeof object == 'object'

  isObjectLiteral: (object) -> @isType(object, 'Object')

  isFunction: (object) -> typeof object == 'function'

  isArray: (object) -> @isType(object, 'Array')

  isString: (object) -> @isType(object, 'String')

  isBoolean: (object) -> @isType(object, 'Boolean')

  isNumber: (object) -> !isNaN(object) && @isType(object, 'Number')
