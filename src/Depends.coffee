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

  # @type {String} name - The name of the resource to add as a dependency.
  # @type {Array.<String>} [deps] - The names of the dependencies the resource depends on.
  # @type {Function} callback - A callback which defines the named dependency. This may optionally
  #     return a result which is passed to the callback of {@link #on}. This may optionally return
  #     a deferred promise and resolve the dependency in the future.
  # @returns {Q.Promise} A promise which is resolved once the named dependency is ready.
  add: (name, deps, callback) ->
    if Types.isFunction(deps)
      callback = deps
      deps = []
    df = @_getDeferred(name)
    log('Added dependency', name, deps)
    @on(deps).then(
      ->
        Q.when(callback()).then(
          (result) ->
            log('Resolved dependency', name)
            df.resolve(result)
          df.reject
        )
      df.reject
    )
    df.promise

  # Rejects the promise for delivering the named dependency and cancels any requests for it with
  # {@link #on}.
  # @type {String} name - The name of the dependency to remove.
  remove: (name) ->
    df = @_deps[name]
    if df
      df.reject('Removed dependency: ' + name)

  # @type {Array.<String>} deps - An array of dependency names.
  # @type {Function} [callback] - If provided, this is used as the success callback once all
  #     dependencies are resolved.
  # @returns {Q.Promise} A promise which is resolved once all dependencies are resolved or rejected
  #     if any could not be resolved.
  on: (deps, callback) ->
    unless deps
      throw new Error('No dependencies provided')
    unless Types.isArray(deps)
      deps = [deps]
    promises = _.map deps, (name) => @_getDeferred(name).promise
    log('Waiting for dependencies', deps)
    Q.all(promises).then (results) ->
      log('Dependencies resolved', deps)
      callback?(results)
      results

log = -> console.log.apply(console, arguments) if Depends.debug
