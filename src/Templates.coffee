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
    options = _.extend({
      template: Template.instance()
      marshall: (value) -> value
      unmarshall: (value) -> return value
      getValue: -> $(this).val()
      setValue: (value) -> $(this).val(value)
      changeEvents: 'change keyup'
    }, options)
    options.template.autorun ->
      value = options.marshall(reactiveVar.get())
      options.setValue.call($em, value)
    $em.on(options.changeEvents, _.debounce((->
      value = options.getValue.call($em)
      reactiveVar.set(options.unmarshall(value))
    ), 500))
