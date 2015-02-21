class DeferredQueue
  
  constructor: ->
    @queue = []

  wait: (index) ->
    promise = @queue[index].promise
    if promise
      promise
    else
      Q.when(null)

  add: (callback) ->
    len = @queue.length
    df = Q.defer()
    @queue.push(df)
    fin = => @queue.shift()
    execute = ->
      result = callback()
      Q.when(result).then(df.resolve, df.reject)
    execute = Meteor.bindEnvironment(execute)
    if len > 0
      @wait(len - 1).then(execute, df.reject).fin(fin)
    else
      execute().fin(fin)
    df.promise

  clear: ->
    _.each @queue, (df) -> df.reject('Clearing DeferredQueue')
