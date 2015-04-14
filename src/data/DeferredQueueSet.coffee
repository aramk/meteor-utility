class DeferredQueueSet extends DeferredQueue

  constructor: ->
    super()
    @index = {}
  
  add: (id, callback) ->
    promise = @index[id]
    unless promise
      promise = super(callback)
      promise.fin =>
        delete @index[id]
    promise
