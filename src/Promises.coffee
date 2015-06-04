Promises =

  serverMethodCall: ->
    df = Q.defer()
    args = Array.prototype.slice.apply(arguments)
    hasCallback = Types.isFunction(_.last(args))
    if hasCallback
      callback = args.pop()
    wrappedCallback = Meteor.bindEnvironment (err, result) ->
      callback?(err, result)
      if err then df.reject(err) else df.resolve(result)
    args.push(wrappedCallback)
    Meteor.call.apply(Meteor, args)
    df.promise

  runSync: (callback) ->
    unless Types.isFunction(callback)
      throw new Error 'Callback must be a function - received ' + Types.getTypeOf(callback)
    response = Async.runSync (done) ->
      try
        callbackResult = callback(done)
        # If returning a deferred object, use the then() method. Otherwise, the callback should use
        # the done() method.
        callbackResult?.then?(
          (result) -> done(null, result)
          (err) -> done(err, null)
        )
      catch err
        done(err, null)
    err = response.error
    if err
      if Meteor.isServer
        if err instanceof Error
          throw new Meteor.Error(500, err.message, err.stack)
        else
          throw new Meteor.Error(500, err)
      else
        throw err
    else
      response.result
