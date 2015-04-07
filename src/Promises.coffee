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
    if response.error
      throw response.error
    else
      response.result
