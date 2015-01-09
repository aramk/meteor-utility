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
  isCursor: (obj) -> obj && Types.isFunction(obj.fetch)

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

  duplicateDoc: (docOrId, collection) ->
    df = Q.defer()
    doc = if Types.isObject(docOrId) then docOrId else collection.findOne(docOrId)
    delete doc._id
    collection.insert doc, (err, result) -> if err then df.reject(err) else df.resolve(result)
    df.promise

  removeAllDocs: (collection) ->
    _.each collection.find().fetch(), (order) ->
      collection.remove(order._id)

  # @param {Meteor.Collection|Cursor|String} collection
  # @param {Object} args
  # @param {Function} [args.added]
  # @param {Function} [args.changed]
  # @param {Function} [args.removed]
  # @param {Function} [args.triggerExisting=false] - Whether to trigger the added callback for
  # existing docs.
  observe: (collection, args) ->
    observing = false
    args = _.extend({triggerExisting: false}, args)
    createHandler = (handler) ->
      -> handler.apply(@, arguments) if observing
    observeArgs = {}
    _.each ['added', 'changed', 'removed'], (methodName) ->
      handler = args[methodName]
      if handler
        observeArgs[methodName] = createHandler(handler)
    cursor = @getCursor(collection)
    handle = cursor.observe(observeArgs)
    observing = true
    if args.triggerExisting
      cursor.forEach (doc) -> observeArgs.added?(doc)
    handle

  # Copies docs from one collection to another and tracks changes in the source collection to apply
  # over time.
  # @param {Meteor.Collection|Cursor} src
  # @param {Meteor.Collection} [dest] - If none is provided, a temporary collection is used.
  # @param {Object} [args]
  # @param {Boolean} [args.track=true] - Whether to observe changes in the source and apply them to
  # the destination over time.
  # @returns {Promise} A promise containing the destination collection once all docs have been
  # copied.
  copy: (src, dest, args) ->
    args = _.extend({track: true}, args)
    dest ?= @createTemporary()
    insertPromises = []

    @getCursor(src).forEach (doc) ->
      return if dest.findOne(doc._id)
      df = Q.defer()
      insertPromises.push(df.promise)
      dest.insert doc, (err, result) -> if err then df.reject(err) else df.resolve(result)
    if args.track
      # Collection2 may not allow inserting a doc into a collection with a predefined _id, so we
      # store a map of src to dest IDs. If a copied doc is removed in the destination, this will
      # still reference the source doc ID to this doc ID.
      idMap = {}
      insert = (srcDoc) ->
        dest.insert srcDoc, (err, insertId) ->
          return if err
          idMap[srcDoc._id] = insertId
      dest.trackHandle = @observe src,
        added: insert
        changed: (newDoc, oldDoc) ->
          id = idMap[newDoc._id]
          # If the document doesn't exist in the destination, don't track changes from the source.
          if dest.findOne(id)
            dest.remove(id)
            insert(newDoc)
        removed: (oldDoc) ->
          id = oldDoc._id
          dest.remove id, (err, result) ->
            return unless result == 1
            delete idMap[id]
    Q.all(insertPromises).then -> dest

  # @param {Array.<Meteor.Collection>} collections
  # @returns {Object.<String, Meteor.Collection>} A map of collection name to object for the given
  # collections.
  getMap: (collections) ->
    collectionMap = {}
    _.each collections, (collection) =>
      name = @getName(collection)
      collectionMap[name] = collection
    collectionMap

  # @returns {String} Generates a MongoDB ObjectID hex string.
  generateId: -> new Mongo.ObjectID().toHexString()

  # @param {Object} doc
  # @param {Object} modifier - A MongoDB modifier object.
  # @returns {Object} A copy of the given doc with the given modifier updates applied.
  simulateModifierUpdate: (doc, modifier) ->
    tmpCollection = @createTemporary()
    doc = Setter.clone(doc)
    # This is synchronous since it's a local collection.
    insertedId = tmpCollection.insert(doc)
    tmpCollection.update(insertedId, modifier)
    tmpCollection.findOne(insertedId)

  # @param {Meteor.Collection} collection
  # @param {Function} validate - A validation method which returns a string on failure or throws
  # an exception, which causes validation to fail and prevents insert() or update() on the collection
  # from completing.
  addValidation: (collection, validate) ->
    collection.before.insert (userId, doc) =>
      @_handleValidationResult(validate(doc))
    collection.before.update (userId, doc, fieldNames, modifier) =>
      doc = @simulateModifierUpdate(doc, modifier)
      @_handleValidationResult(validate(doc))

  _handleValidationResult: (result) ->
    # TODO(aramk) The deferred won't run in time since hooks are not asynchronous yet, so it won't
    # prevent the collection methods from being called.
    # https://github.com/matb33/meteor-collection-hooks/issues/71
    handle = (invalid) -> throw new Error(invalid) if invalid
    if result && result.then
      result.then(handle, handle)
    else
      handle(result)

  intersection: (a, b) ->
    result = @createTemporary()
    a.find().forEach (item) ->
      if b.findOne(item._id)
        result.insert(item)
    result
