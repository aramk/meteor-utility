Numbers =

  isDefined: (value) -> value != '' && value? && !isNaN(value)

  isFloat: (value) -> value? && value.toString().indexOf('.') >= 0
