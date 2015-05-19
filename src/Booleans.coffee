Booleans =

  parse: (obj) ->
    if !obj?
      # Do not attempt to parse null or undefined values.
      obj
    if Types.isBoolean(obj)
      obj
    else if Types.isString(obj)
      obj == '1' || obj == 'true'
    else
      !!obj
