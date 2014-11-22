Templates =

  getNamed: (name) ->
    template = Template.instance()
    unless template
      throw new Error('No current template found.')
    view = template.view
    unless view
      throw new Error('No view for current template found.')
    viewQueue = [view]
    while viewQueue.length > 0
      view = viewQueue.pop()
      template = view._templateInstance
      break if view.name == 'Template.' + name
      viewQueue.push(view.parentView)
    template

  getDom: (component) -> component._domrange.parentElement
