Booleans =

  parse: (obj) ->
    # Do not attempt to parse null or undefined values.
    if !obj? then return obj
    if Types.isBoolean(obj)
      obj
    else if Types.isString(obj)
      obj == '1' || obj == 'true'
    else
      !!obj
