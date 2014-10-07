global = @

Collections =

  allow: -> true
  allowAll: -> insert: @allow, update: @allow, remove: @allow

# @param {Meteor.Collection|Cursor|String} arg
# @returns {String}
  getName: (arg) ->
    collection = @get(arg)
    # Meteor.Collection or LocalCollection.
    if collection then (collection._name || collection.name) else null

  getTitle: (arg) ->
    Strings.toTitleCase(@getName(arg))

# @param {String|Meteor.Collection|Cursor} arg
# @returns The underlying collection or null if none is found.
  get: (arg) ->
    if Types.isString(arg)
      # Collection name.
      global[arg]
    else if @isCursor(arg)
      arg.collection
    else if @isCollection(arg)
      arg
    else
      null

# @param {String|Meteor.Collection|Cursor} arg
# @returns The underlying Cursor or null if none is found.
  getCursor: (arg) ->
    if @isCursor(arg)
      arg
    else
      collection = @get(arg)
      collection.find()

# @param {String|Meteor.Collection|Cursor} arg
# @returns {Meteor.Collection|Cursor} Either a Meteor collection, a cursor, or null if none is
# found.
  resolve: (arg) ->
    if Types.isString(arg)
      # Collection name.
      return global[arg]
    else if @isCursor(arg)
      return arg
    else if @isCollection(arg)
      return arg
    else
      return null

# @param obj
# @returns {Boolean} Whether the given object is a collection.
  isCollection: (obj) ->
    obj instanceof Meteor.Collection

# @param obj
# @returns {Boolean} Whether the given object is a collection cursor.
  isCursor: (obj) ->
    obj.fetch != undefined

# @param {Meteor.Collection|Cursor|Array} arg
# @returns {Array} The items in the collection, or the cursor, or the original array passed.
  getItems: (arg) ->
    if Types.isArray(arg)
      return arg
    if Types.isString(arg)
      arg = @get(arg)
    if @isCollection(arg)
      arg = arg.find({})
    if @isCursor(arg)
      return arg.fetch()
    return []

  createTemporary: -> new Meteor.Collection(null)

  isTemporary: (collection) -> !@getName(collection)

  moveDoc: (id, sourceCollection, destCollection) ->
    order = sourceCollection.findOne(id)
    unless order
      throw new Error('Could not find doc with id ' + id + ' in collection ' + sourceCollection)
    destCollection.insert order, (err, result) ->
      if err
        throw new Error('Failed to insert into destination collection when moving')
      else
        sourceCollection.remove id, (err2, result2) ->
          if err2
            throw new Error('Failed to remove from source collection when moving')

  removeAllDocs: (collection) ->
    _.each collection.find().fetch(), (order) ->
      collection.remove(order._id)

# @param {Meteor.Collection|Cursor|String} arg
# @param {Object} args
# @param {Function} [args.added]
# @param {Function} [args.changed]
# @param {Function} [args.removed]
  observe: (collection, args) ->
    observing = false
    args ?= {}
    createHandler = (handler) ->
      -> handler.apply(@, arguments) if observing
    observeArgs = {}
    _.each ['added', 'changed', 'removed'], (methodName) ->
      handler = args[methodName]
      if handler
        observeArgs[methodName] = createHandler(handler)
    handle = @getCursor(collection).observe(observeArgs)
    # If on the client, wait for the collection subscription to finish to avoid triggering
    # the create handler as new items are added. Don't subscribe to unmanaged local collections
    # which are unnamed.
    if Meteor.isClient && !@isTemporary(collection)
      Meteor.subscribe @getName(collection), -> observing = true
    else
      observing = true
    handle

# @param {Array.<Meteor.Collection>} collections
# @returns {Object.<String, Meteor.Collection>} A map of collection name to object for the given
# collections.
  getMap: (collections) ->
    collectionMap = {}
    _.each collections, (collection) =>
      name = @getName(collection)
      collectionMap[name] = collection
    collectionMap
