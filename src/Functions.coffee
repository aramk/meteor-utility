Functions =

  # Similar to _.debounce, but the initial call will excute the given function instead of waiting
  # for the given delay.
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
