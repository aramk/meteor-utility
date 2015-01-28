Promises =

  serverMethodCall: ->
    df = Q.defer()
    hasCallback = Types.isFunction(callback)
    args = Array.prototype.slice.apply(arguments)
    if hasCallback
      callback = args.pop()
    wrappedCallback = Meteor.bindEnvironment (err, result) ->
      if hasCallback
        callback(err, result)
      if err then df.reject(err) else df.resolve(result)
    args.push(wrappedCallback)
    Meteor.call.apply(Meteor, args)
    df.promise
