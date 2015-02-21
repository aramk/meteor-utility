class DeferredQueueMap
  
  constructor: ->
    @queues = {}

  add: (id, callback) ->
    queue = @queues[id] ?= new DeferredQueue()
    queue.add(callback)

  clear: ->
    _.each @queues, (queue) -> queue.clear()
