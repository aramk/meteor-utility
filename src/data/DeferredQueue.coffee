class DeferredQueue
  
  constructor: ->
    @queue = []

  wait: (index) ->
    promise = @queue[index]
    if promise
      promise
    else
      Q.when(null)

  add: (callback) ->
    len = @queue.length
    df = Q.defer()
    @queue.push(df.promise)
    fin = => @queue.shift()
    execute = ->
      result = callback()
      Q.when(result).then(df.resolve, df.reject)
    if Meteor.isServer
      execute = Meteor.bindEnvironment(execute)
    if len > 0
      @wait(len - 1).then(execute, df.reject).fin(fin)
    else
      execute().fin(fin)
    df.promise
