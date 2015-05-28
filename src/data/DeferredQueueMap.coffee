class DeferredQueueMap
  
  constructor: (options) ->
    @queues = {}
    @options = Setter.merge({
      exclusive: false
    }, options)

  add: (id, callback) ->
    queue = @queues[id] ?= new DeferredQueue()
    if @options.exclusive && queue.size() > 0
      _.first(queue.getItems()).promise
    else
      queue.add(callback)

  clear: -> _.each @queues, (queue) -> queue.clear()

  wait: (id) ->
    queue = @queues[id]
    return Q.when() unless queue
    queue.waitForAll()

  waitForAll: -> Q.all _.map @queues, (queue, id) => @wait(id)
