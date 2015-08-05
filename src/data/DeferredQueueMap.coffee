class DeferredQueueMap
  
  constructor: (options) ->
    @queues = {}
    @waitCallbacks = []
    @options = Setter.merge({
      exclusive: false
    }, options)

  add: (id, callback) ->
    queue = @get(id)
    if @options.exclusive && queue.size() > 0
      _.first(queue.getItems()).promise
    else
      queue.add(callback)

  get: (id) -> @queues[id] ?= new DeferredQueue()

  clear: -> _.each @queues, (queue) -> queue.clear()

  wait: (id) ->
    queue = @queues[id]
    return Q.when() unless queue
    queue.waitForAll()

  waitForAll: -> Q.all _.map @queues, (queue, id) => @wait(id)

  waitSync: (id, callback) ->
    queue = @queues[id]
    unless queue
      callback()
      return undefined
    queue.waitForAllSync(callback)

  waitForAllSync: (callback) ->
    count = @size()
    if count == 0
      callback()
      return
    eachCallback = ->
      count--
      if count == 0 then callback()
    _.each @queues, (queue, id) => @waitSync(id, eachCallback)
    return undefined

  size: -> _.keys(@queues).length
