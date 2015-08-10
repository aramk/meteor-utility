class DeferredQueue
  
  constructor: ->
    @queue = []
    # A list of callbacks which are fired once all promises in the queue are resolved.
    @waitCallbacks = []

  wait: (index) ->
    promise = @queue[index].promise
    if promise then promise else Q.when(null)

  waitForAll: -> Q.all _.map @queue, (df) -> df.promise

  waitForAllSync: (callback) ->
    @waitCallbacks.push(callback)
    @_resolveWaiting()
    return undefined

  _resolveWaiting: ->
    return unless _.isEmpty(@queue)
    _.each @waitCallbacks, (callback) -> callback()
    @waitCallbacks = []

  add: (callback) ->
    len = @queue.length
    df = Q.defer()
    @queue.push(df)
    fin = =>
      @queue.shift()
      @_resolveWaiting()
    execute = Meteor.bindEnvironment =>
      # If the promise is fulfilled due to a clear() then avoid running the callback.
      unless df.promise.isPending() then return
      try
        df.resolve(callback())
      catch e
        df.reject(e)
    if len > 0
      @wait(len - 1).then(execute, df.reject)
    else
      execute()
    df.promise.fin(fin)
    df.promise

  size: -> @queue.length

  getItems: -> _.clone(@queue)

  clear: -> _.each @queue, (df) -> df.reject('Clearing DeferredQueue')
