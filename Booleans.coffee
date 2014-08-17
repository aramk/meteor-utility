@Booleans =

  parse: (obj) ->
    if Types.isBoolean(obj)
      obj
    else if Types.isString(obj)
      obj == '1' || obj == 'true'
    else
      !!obj
