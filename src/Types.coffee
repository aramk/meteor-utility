Types =

  getTypeOf: (object) ->
    Object.prototype.toString.call(object).slice(8, -1)

  isType: (object, type) ->
    if object? then this.getTypeOf(object) == type else object == type

  isObject: (object) -> object? and typeof object == 'object' or @isFunction(object) or
      @isArray(object)

  isObjectLiteral: (object) -> object? and typeof object == 'object' and !@isFunction(object) and
      !@isArray(object)

  isFunction: (object) -> typeof object == 'function'

  isArray: (object) -> Array.isArray?(object) ? @isType(object, 'Array')

  isString: (object) -> @isType(object, 'String')

  isBoolean: (object) -> @isType(object, 'Boolean')

  isNumber: (object) -> !isNaN(object) and @isType(object, 'Number')
