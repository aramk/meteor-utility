Numbers =

  isDefined: (value) -> value != '' && value? && !isNaN(value)

  isFloat: (value) -> value? && value.toString().indexOf('.') >= 0

  parse: (value) -> if typeof value == 'number' then value else parseFloat(value)
