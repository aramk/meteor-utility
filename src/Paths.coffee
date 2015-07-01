Paths =

  dirname: (path, times = 1) ->
    path = @_clean(path)
    @_repeatExec ((path) -> path.replace /\/[^/]*$/, ''), path, times

  basename: (path, times = 1) -> @_repeatExec ((path) => @_firstMatch path, /[^/]*$/), path, times

  filename: (path) -> @basename(path).replace('.' + @extension(path, true), '')

  extension: (path) ->
    ext = @_firstMatch(path, /\.[^./]*$/)
    if ext then ext.replace('.', '') else ext

  join: ->
    path = ''
    i = 0
    while i < arguments.length
      path = @addLastSlash(path + arguments[i])
      i++
    path

  isRelative: (path) -> /^(?!\/)[\s\S]/.test(path)

  _firstMatch: (str, regex) ->
    str = @_clean(str)
    match = str.match(regex)
    if match and match.length > 0 then match[0] else null

  _repeatExec: (callback, arg, times) ->
    i = 0
    while i < times
      arg = callback(arg)
      i++
    arg

  _clean: (obj) ->
    obj ?= ''
    unless Types.isString(obj)
      throw new Error('Value passed to Paths must be a string')
    obj

  addLastSlash: (path) ->
    last = path.substr(path.length - 1)
    if last == '/' then path else path + '/'

  removeLastSlash: (path) -> path.replace /\/$/, ''

  removeQuery: (url) -> url.replace /\?.*/, ''
