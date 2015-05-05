Log =

  # The current level of logging.
  level: 'info'

  _levels:
    off: 0
    error: 1
    warn: 2
    info: 3
    time: 4
    debug: 5

  _timers: {}

  setLevel: (level) ->
    if @_levels[level]?
      @level = level

  _loggingOn: true

  shouldLog: (level, currentLevel) ->
    currentLevel ?= @level
    # Only logs if the level is less than or equal to the current level
    code = @_levels[level]
    return typeof code != 'undefined' && code <= @_levels[currentLevel]

  on: ->
    return if @_loggingOn
    @_loggingOn = true
    _.each Object.keys(FunctionReferences), (f) => @[f] = FunctionReferences[f]

  off: ->
    return unless @_loggingOn
    @_loggingOn = false
    _.each Object.keys(FunctionReferences), (f) => @[f] = ->

  debug: -> @shouldLog('debug') && Log.msg('DEBUG', arguments, console.debug)

  info: -> @shouldLog('info') && Log.msg('INFO', arguments)

  warn: -> @shouldLog('warn') && Log.msg('WARNING', arguments, console.warn)

  error: -> @shouldLog('error') && Log.msg('ERROR', arguments, console.error)

  msg: (msg, args, func) ->
    return if @level == 'off'
    func = Setter.defaultValue(func, console.log)
    args = Array.prototype.slice.call(args)
    args.splice(0, 0, '[' + msg + '] ')
    func.apply(console, args)
    # Logging should have no return.
    return undefined

  trace: ->
    e = new Error('dummy')
    stack = e.stack.replace(/^[^\(]+?[\n$]/gm, '')
        .replace(/^\s+at\s+/gm, '')
        .replace(/^Object.<anonymous>\s*\(/gm, '{anonymous}()@')
        .split('\n')
    console.log(stack)

  time: (name, level) ->
    if level != undefined
      @_timers[name] =
        date: Date.now()
        level: level
    else if @shouldLog('time')
      console.time(name)

  timeEnd: (name) ->
    timer = @_timers[name]
    if timer
      if @shouldLog(timer.level)
        Log[timer.level](name + ': ' + (Date.now() - timer.date) + 'ms')
      delete @_timers[name]
    else if @shouldLog('time')
      console.timeEnd(name)

# Allows setting the logging level via GET variable
if typeof Window != 'undefined'
  logGet = Window.GET('log')
  if logGet
    Log.setLevel(logGet)

FunctionReferences =
  info: Log.info
  debug: Log.debug
  error: Log.error
  warn: Log.warn
  time: Log.time
  timeEnd: Log.timeEnd

global = @
console = global.console

# For those without a console
if typeof console == 'undefined'
  console = {}
  funcs = ['log', 'debug', 'error', 'warn', 'time', 'timeEnd']
  _.each FunctionReferences, (func, funcName) ->
    # Ignorance is bliss
    console[funcName] = ->

if Meteor?
  # Log is already defined in the logging pacakge, so we define a different global variable for now.
  Logger = Log
