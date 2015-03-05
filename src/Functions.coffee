Functions =

  debounceLeft: (func, delay) ->
    isPressed = false
    handle = null
    call = (args) ->
      func.apply(null, args)
      press(arguments, false)
    press = (args, shouldCall) ->
      shouldCall ?= true
      isPressed = true
      clearTimeout(handle)
      handle = setTimeout(
        ->
          isPressed = false
          shouldCall && call(args)
        delay
      )
    wrapped = ->
      if isPressed
        press(arguments, true)
        return
      call(arguments)
      return
    wrapped
