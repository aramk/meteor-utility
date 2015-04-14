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

  clear: ->
    _.each @queues, (queue) -> queue.clear()
