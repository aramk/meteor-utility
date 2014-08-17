SimpleSchema.debug = true
SimpleSchema.extendOptions
# Optional extra fields.
# TODO(aramk) These are added globally, not just for typologies.
  desc: Match.Optional(String)
  units: Match.Optional(String)
# TODO(aramk) There's no need to use serialized formulas, since functions are first-class objects
# and we don't need to persist or change them outside of source code.

# An expression for calculating the value of the given field for the given model. These are output
# fields and do not appear in forms. The formula can be a string containing other field IDs prefixed
# with '$' (e.g. $occupants) which are resolved to the local value per model, or global parameters
# if no local equivalent is found.

# If the expression is a function, it is passed the current model
# and the field and should return the result.
  calc: Match.Optional(Match.Any)
# A map of class names to objects of properties. "defaultValues" specifies the default value for
# the given class.
  classes: Match.Optional(Object)

global = @

@Collections =

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
      return global[arg]
    else if @isCursor(arg)
      return arg.collection
    else if @isCollection(arg)
      return arg
    else
      return null

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

  createTemporary: ->
    new Meteor.Collection(null)
