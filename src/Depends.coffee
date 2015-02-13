# Manages dependencies between modules to allow decoupling and asynchronous loading.
Depends =

  # @type {Boolean} [debug=false] - Whether to log actions.
  debug: false

  # @type{Object.<String, Q.Deferred>} A map of dependency IDs to their deferred promises.
  _deps: {}

  # @returns {Q.Deferred} Creates or returns a deferred promise for the dependency with the given
  #     name.
  _getDeferred: (name) ->
    @_deps[name] ?= Q.defer()

  # @type {String} name - The name of the resource to define as a dependency.
  # @type {Array.<String>|String} [deps] - The names of the dependencies the resource depends on.
  # @type {Function|*} value - A value which defines the named dependency. This may
  #     optionally be a callback which returns a result, or one which returns a deferred promise.
  #     If the value of this argument is not a function, it is resolved as the result of the
  #     dependency.
  # @returns {Q.Promise} A promise which is resolved once the named dependency is ready.
  define: (name, deps, value) ->
    unless Types.isString(deps) || Types.isArray(deps)
      value = deps
      deps = []
    isCallback = Types.isFunction(value)
    if isCallback
      value = bindMeteor(value)
    df = @_getDeferred(name)
    log('Defined dependency', name, deps)
    @on(deps).then(
      bindMeteor (depsResult) ->
        value = if isCallback then value.apply(null, depsResult) else value
        Q.when(value).then(
          bindMeteor (valueResult) ->
            log('Resolved dependency', name, valueResult)
            df.resolve(valueResult)
          df.reject
        ).done()
      df.reject
    ).done()
    df.promise

  # Rejects the promise for delivering the named dependency and cancels any requests for it with
  # {@link #on}.
  # @type {String} name - The name of the dependency to remove.
  remove: (name) ->
    df = @_deps[name]
    if df
      df.reject('Removed dependency: ' + name)

  # @type {Array.<String>|String} deps - An array of dependency names.
  # @type {Function} [callback] - If provided, this is used as the success callback once all
  #     dependencies are resolved.
  # @returns {Q.Promise} A promise which is resolved once all dependencies are resolved or rejected
  #     if any could not be resolved.
  on: (deps, callback) ->
    unless deps
      throw new Error('No dependencies provided')
    unless Types.isArray(deps)
      deps = [deps]
    if callback
      callback = bindMeteor(callback)
    promises = _.map deps, (name) => @_getDeferred(name).promise
    log('Waiting for dependencies', deps)
    promise = Q.all(promises)
    promise.then bindMeteor (results) ->
      log('Dependencies resolved', deps, results)
      callback?(results)
      promise
    promise

log = -> console.log.apply(console, arguments) if Depends.debug
bindMeteor = -> Meteor.bindEnvironment.apply(Meteor, arguments)
