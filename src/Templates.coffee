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
    if templateInstance instanceof Blaze.TemplateInstance
      view = templateInstance.view
    else if templateInstance instanceof Blaze.View
      view = templateInstance
    unless view
      throw new Error('No view for current template found.')
    viewQueue = [view]
    while viewQueue.length > 0
      view = viewQueue.pop()
      break unless view
      # If no template instance is found, keep the given instance as a fallback.
      if view.name == 'Template.' + name
        templateInstance = view.templateInstance?() ? templateInstance
        break
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
    reactiveVar ?= new ReactiveVar()
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
          else if Numbers.isDefined(min) and value < min
            value = min
          else if Numbers.isDefined(max) and value > max
            value = max
        value
      getValue: -> $(this).val()
      setValue: (value) -> $(this).val(value)
      setReactiveVariable: (reactiveVar, value) -> reactiveVar.set(value)
      getReactiveVariable: (reactiveVar) -> reactiveVar.get()
      changeEvents: 'change keyup'
      debounce: true
      delay: 500
    }, options)
    options.template ?= Template.instance()

    initialElementValue = options.unmarshall options.getValue.call($em)
    intialReactiveValue = options.getReactiveVariable(reactiveVar)
    # If the element has a value but the reactive variable doesn't, use the element value as the
    # initial value.
    if !intialReactiveValue? and initialElementValue?
      options.setReactiveVariable(reactiveVar, initialElementValue)

    options.template.autorun ->
      value = options.getReactiveVariable(reactiveVar)
      options.setValue.call $em, options.marshall(value)
    
    update = ->
      value = options.getValue.call($em)
      newValue = options.unmarshall(value)
      if newValue != options.getReactiveVariable(reactiveVar)
        reactiveVar.set(newValue)
    if options.debounce
      update = _.debounce(update, options.delay)
    $em.on(options.changeEvents, update)

    reactiveVar

  bindVarToCheckbox: ($em, reactiveVar, options) ->
    @bindVarToElement($em, reactiveVar, _.extend({
      getValue: -> $(@).is(':checked')
      setValue: (value) ->
        value = !!value
        wasChecked = $(@).is(':checked')
        unless wasChecked == value then $(@).prop('checked', value).trigger('change')
    }, options))

  bindSessionToElement: ($em, sessionVarName, options) ->
    reactiveVar = @bindVarToSession(null, sessionVarName, options)
    @bindVarToElement($em, reactiveVar, options)

  bindVarToSession: (reactiveVar, sessionVarName, options) ->
    reactiveVar ?= new ReactiveVar()
    options = _.extend({
      template: Template.instance()
      setSession: (name, value) -> Session.set(name, value)
      getSession: (name) -> Session.get(name)
      setReactiveVariable: (reactiveVar, value) -> reactiveVar.set(value)
      getReactiveVariable: (reactiveVar) -> reactiveVar.get()
    }, options)
    options.template.autorun ->
      value = options.getSession(sessionVarName)
      reactiveValue = Tracker.nonreactive -> options.getReactiveVariable(reactiveVar)
      # Prevent setting undefined on an existing reactive variable value if the session has not
      # yet been set.
      unless value == undefined and reactiveValue?
        options.setReactiveVariable(reactiveVar, value)
    options.template.autorun ->
      value = options.getReactiveVariable(reactiveVar)
      # Since the reactive variable was only set if the session was defined, the session can be
      # safely set with the reactive variable value.
      options.setSession(sessionVarName, value)
    reactiveVar

  get: (templateOrName) ->
    if templateOrName instanceof Blaze.Template
      templateOrName
    else
      Template[templateOrName]

