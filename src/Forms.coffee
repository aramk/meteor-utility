Forms =

  FIELD_SELECTOR: '.form-group',

  defineModelForm: (formArgs) ->
    name = formArgs.name
    Form = Template[name]
    unless Form
      throw new Error 'No template defined with name ' + name

    deferCallback = (result, callback) ->
      # Defer the callback if the result is a promise. Ignore if result is false. Otherwise execute
      # callback immediately.
      unless result == false
        if result?.then
          result.then -> callback()
        else
          callback()

    getAutoFormTemplateInstance = -> Blaze.getView($('form#' + name)[0]).templateInstance()

    getTemplateInstance = -> Templates.getNamedInstance(name, getAutoFormTemplateInstance())

    AutoForm.addHooks name,
      # Settings should be passed to the autoForm helper to ensure they are available in these
      # callbacks.
      onSubmit: (insertDoc, updateDoc, currentDoc) ->
        args = arguments
        template = @template
        console.debug 'onSubmit', args, @
        result = formArgs.onSubmit?.apply(@, args)
        formTemplate = getTemplateInstance()
        callback = -> formTemplate.data?.settings?.onSubmit?.apply(@, args)
        deferCallback(result, callback)

      onSuccess: (operation, result, template) ->
        args = arguments
        formTemplate = getTemplateInstance()
        console.debug 'onSuccess', args, @
        AutoForm.resetForm(name)
        result = formArgs.onSuccess?.apply(@, args)
        callback = -> formTemplate.data?.settings?.onSuccess?.apply(@, args)
        deferCallback(result, callback)

      onError: (operation, error, template) ->
        console.error('Error submitting form', operation, error, template)
        throw new Error(error)

      before:
        insert: (doc, template) ->
          console.debug('before insert', doc)
          doc
        update: (docId, modifier, template) ->
          console.debug('before update', docId, modifier)
          modifier

    if formArgs.hooks?
      AutoForm.addHooks name, formArgs.hooks

    Form.helpers
      collection: -> Collections.get(formArgs.collection)
      formName: -> name
    # Without this a separate copy is passed across, which doesn't allow sharing data between
    # create method and form hooks.
      doc: -> @doc
      formTitle: ->
        collectionName = Collections.getTitle(formArgs.collection)
        (if @doc then 'Edit' else 'Create') + ' ' + Strings.singular(collectionName)
      formType: ->
        if @doc then 'update' else 'insert'
      submitText: -> if @doc then 'Save' else 'Create'

    Form.events
      'click button.cancel': (e, template) ->
        e.preventDefault()
        console.debug 'onCancel', arguments, @
        formArgs.onCancel?(template)
        formTemplate = getTemplateInstance()
        formTemplate.data?.settings?.onCancel?()

    Form.created = ->
      formArgs.onCreate?.apply(@, arguments)

    Form.rendered = ->
      console.debug 'Rendered form', @, arguments
      # Move the buttons to the same level as the title and content to allow using flex-layout.
      $buttons = @$('.crud.buttons')
      $crudForm = @$('.flex-panel')
      if $buttons.length > 0 && $crudForm.length > 0
        $crudForm.append($buttons)
      @$('[type="submit"]', $buttons).click => @$('form', $crudForm).submit()
      AutoForm.resetForm(name)

      collection = Collections.get(formArgs.collection)
      @schemaInputs = Forms.getSchemaInputs(@, collection)

      popupInputs = []
      hasRequiredField = false
      for key, input of @schemaInputs
        $input = $(input.node)
        field = input.field
        desc = field.desc
        # Add popups to the inputs contain definitions from the schema.
        if desc?
          popupInputs.push($input.data('desc', desc))
        # Add units into labels
        $label = @$('label[for="' + key + '"]')
        if $label.length == 0
          $parent = $input.parent()
          if $parent.is('.dropdown')
            $label = $parent.prev('label')

        units = field.units
        $labelContent = $('<div class="value">' + $label.html() + '</div>')
        $label.empty()
        $label.append($labelContent)
        if units?
          formattedUnits = Strings.format.scripts(units)
          $units = $('<div class="units">' + formattedUnits + '</div>')
          $label.append($units)
        required = field.optional == false
        if required
          Forms.addRequiredLabel($label)
          hasRequiredField = true

      if hasRequiredField
        @$('.ui.form.segment').append($('<div class="footer"><div class="required"></div>Required field</div>'))

      addPopups = ->
        $(popupInputs).each ->
          $input = $(@)
          $input.data('desc')
          $input.popup('setting', delay: 500, content: $input.data('desc'))

      removePopups = ->
        $(popupInputs).popup('destroy')

      @autorun (c) ->
        helpMode = Session.get 'helpMode'
        if helpMode then addPopups() else removePopups()
      formArgs.onRender?.apply(@, arguments)

    Form.destroyed = ->
      console.debug 'Destroyed form', @, arguments
      template = @
      template.isDestroyed = true
      formArgs.onDestroy?.apply(@, arguments)

    return Form

  addRequiredLabel: ($label) ->
    $requiredContent = $('<div class="required"></div>')
    $label.append($requiredContent)

# We may pass the temporary collection as an attribute to autoform templates, so we need to
# define this to avoid errors since it is passed into the actual <form> HTML object.
  preventText: (obj) ->
    obj.toText = -> ''
    obj

  findFieldInput: (template, name) ->
    template.find('[name="' + name + '"]')

  getSchemaInputs: (template, collection) ->
    $schemaInputs = template.$('[data-schema-key]')
    schema = collection.simpleSchema()
    schemaInputs = {}
    if schema?
      $schemaInputs.each ->
        $input = $(@)
        key = $input.attr('data-schema-key')
        field = schema.schema(key)
        if field
          schemaInputs[key] =
            node: @
            key: key
            field: field
        else
          console.warn('Unrecognised data-schema-key', key, 'for schema', schema)
    schemaInputs
