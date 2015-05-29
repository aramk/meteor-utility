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
  _loggingOn: true
  _showTimetamps: false

  setLevel: (level) -> if @_levels[level]? then @level = level

  setShowTimestamps: (show) -> @_showTimetamps = show

  shouldLog: (level, currentLevel) ->
    currentLevel ?= @level
    # Only logs if the level is less than or equal to the current level
    code = @_levels[level]
    return typeof code != 'undefined' && code <= @_levels[currentLevel]

  # Enables the Log functions if they have been disabled.
  on: ->
    return if @_loggingOn
    @_loggingOn = true
    _.each Object.keys(FunctionReferences), (f) => @[f] = FunctionReferences[f]

  # Disables the Log functions.
  off: ->
    return unless @_loggingOn
    @_loggingOn = false
    _.each Object.keys(FunctionReferences), (f) => @[f] = ->

  debug: -> @shouldLog('debug') && @msg('DEBUG', arguments, console.debug)

  info: -> @shouldLog('info') && @msg('INFO', arguments)

  warn: -> @shouldLog('warn') && @msg('WARN', arguments, console.warn)

  error: -> @shouldLog('error') && @msg('ERROR', arguments, console.error)

  # Prints the message in `args` to the console function `func` (defaults to `console.log`),
  # prepended with the string `[channel]`.
  msg: (channel, args, func) ->
    return if @level == 'off'
    func = Setter.defaultValue(func, console.log)
    # Ensure the message string is at least five characters for prettier printing.
    padding = ''
    if channel.length < 5 then padding = new Array(6 - channel.length).join(' ')
    args = _.toArray(args)
    stamp = '[' + channel + ']' + padding
    if @_showTimetamps then stamp += '[' + moment().format() + ']'
    args.splice(0, 0, stamp + ' ')
    func.apply(console, args)
    # Logging should have no return.
    return undefined

  # Prints a stack trace from the caller's point of execution.
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
if Window?
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

# For those without a console.
if typeof console == 'undefined'
  console = {}
  _.each FunctionReferences, (func, funcName) ->
    # Ignorance is bliss
    console[funcName] = ->

if Meteor?
  # Log is already defined in the logging package, so we define a different global variable for now.
  Logger = Log
  if Meteor.isServer
    logLevel = process.env.LOG_LEVEL
    if logLevel?
      console.log('Log level:', logLevel)
      Logger.setLevel(logLevel)
