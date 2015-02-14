class DeferredQueueMap
  
  constructor: ->
    @queues = {}

  add: (id, callback) ->
    queue = @queues[id] ?= new DeferredQueue()
    queue.add(callback)
