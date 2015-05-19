Templates =

  # @param {String} name - The template name, excluding the "Template." prefix.
  # @param {Blaze.Template} [templateInstance] - The starting template to use for traversing up the
  # template hierarchy. By default this will be the current template instance in the scope.
  # @returns {Blaze.TemplateInstance} The template instance in the current hierarchy with the given
  # name.
  getNamedInstance: (name, templateInstance) ->
    templateInstance = templateInstance ? Template.instance()
    unless templateInstance
      throw new Error('No current template found.')
    view = templateInstance.view
    unless view
      throw new Error('No view for current template found.')
    viewQueue = [view]
    while viewQueue.length > 0
      view = viewQueue.pop()
      return unless view
      templateInstance = view.templateInstance?()
      break if view.name == 'Template.' + name
      viewQueue.push(view.parentView)
    templateInstance

  getInstanceFromElement: (em) ->
    $em = $(em)
    view = Blaze.getView($em[0])
    return unless view
    view.templateInstance()

  getElement: (view) -> view._domrange.parentElement

  bindVarToElement: ($em, reactiveVar, options) ->
    $em = $($em)
    if $em.length == 0
      throw new Error('Invalid element')
    unless reactiveVar instanceof ReactiveVar
      throw new Error('Invalid reactive variable')
    isNumber = $em.attr('type') == 'number'
    min = parseFloat($em.attr('min'))
    max = parseFloat($em.attr('max'))
    options = _.extend({
      marshall: (value) -> value
      unmarshall: (value) ->
        if isNumber
          value = parseFloat(value)
          unless Numbers.isDefined(value)
            value = null
          else if Numbers.isDefined(min) && value < min
            value = min
          else if Numbers.isDefined(max) && value > max
            value = max
        value
      getValue: -> $(this).val()
      setValue: (value) -> $(this).val(value)
      changeEvents: 'change keyup'
      debounce: true
      delay: 500
    }, options)
    options.template ?= Template.instance()
    options.template.autorun ->
      value = options.marshall(reactiveVar.get())
      options.setValue.call($em, value)
    update = ->
      value = options.getValue.call($em)
      newValue = options.unmarshall(value)
      if newValue != reactiveVar.get()
        reactiveVar.set(newValue)
      options.setValue.call($em, newValue)
    if options.debounce
      update = _.debounce(update, options.delay)
    $em.on(options.changeEvents, update)

  bindVarToCheckbox: ($em, reactiveVar, options) ->
    @bindVarToElement($em, reactiveVar, _.extend({
      getValue: -> $(@).is(':checked')
      setValue: (value) -> $(@).prop('checked', value)
    }, options))

  bindSessionToElement: ($em, sessionVarName, options) ->
    reactiveVar = @bindVarToSession(null, sessionVarName, options)
    @bindVarToElement($em, reactiveVar, options)

  bindVarToSession: (reactiveVar, sessionVarName, options) ->
    reactiveVar ?= new ReactiveVar()
    options = _.extend({
      template: Template.instance()
    }, options)
    options.template.autorun ->
      value = Session.get(sessionVarName)
      reactiveVar.set(value)
    options.template.autorun ->
      value = reactiveVar.get()
      Session.set(sessionVarName, value)
    reactiveVar

  get: (templateOrName) ->
    if templateOrName instanceof Blaze.Template
      templateOrName
    else
      Template[templateOrName]

