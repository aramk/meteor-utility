@Window =

  addSlash: (str) ->
    str.replace(/(?!\/)(.)$/, '$1/')

  getQueryParams: (qs) ->
    # http://stackoverflow.com/questions/439463
    qs = qs.split('+').join(' ')
    params = {}
    re = /[?&]?([^=]+)=([^&]*)/g
    while tokens = re.exec(qs)
      params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2])
    params

  currentURL: (_window) ->
    _window = _window || window
    window.location.protocol + '//' + window.location.host + window.location.pathname

  currentHost: (_window) ->
    _window = _window || window
    @addSlash(_window.location.protocol + '//' + _window.location.host)

  currentDir: ->
    @addSlash(@currentURL().substring(0, @currentURL().lastIndexOf('/')))

  GET: (key, _document) ->
    _document = _document || document
    GET = @getQueryParams(_document.location.search)
    if key then GET[key] else GET

  isEnabled: (name) ->
    setting = @GET(name)
    if setting != undefined then setting != '0' else true

  getVarBool: (name) ->
    variable = @GET(name)
    if variable == undefined then undefined else !!parseInt(variable)
