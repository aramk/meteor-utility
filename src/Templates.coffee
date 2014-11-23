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
      templateInstance = view.templateInstance?()
      break if view.name == 'Template.' + name
      viewQueue.push(view.parentView)
    templateInstance

  getDom: (view) -> view._domrange.parentElement
