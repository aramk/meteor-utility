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

    AutoForm.addHooks name,
      # Settings should be passed to the autoForm helper to ensure they are available in these
      # callbacks.
      onSubmit: (insertDoc, updateDoc, currentDoc) ->
        args = arguments
        template = @template
        console.debug 'onSubmit', args, @
        onSubmit = formArgs.onSubmit ? formArgs.hooks?.onSubmit
        result = onSubmit?.apply(@, args)
        formTemplate = getTemplate(template)
        callback = => formTemplate.settings.onSubmit?.apply(@, args)
        deferCallback(result, callback)
        # If no result is provided, prevent the form submission from refreshing the page.
        return (result ? false)

      onSuccess: (operation, result, template) ->
        args = arguments
        formTemplate = getTemplate(template)
        console.debug 'onSuccess', args, @
        AutoForm.resetForm(name)
        onSuccess = formArgs.onSuccess ? formArgs.hooks?.onSuccess
        result = onSuccess?.apply(@, args)
        callback = => formTemplate.settings.onSuccess?.apply(@, args)
        deferCallback(result, callback)

      onError: (operation, error, template) ->
        console.error('Error submitting form', operation, error, template)
        onError = formArgs.onError ? formArgs.hooks?.onError
        onError?.apply(@, args)
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
      schema: -> formArgs.schema
      formName: -> name
    # Without this a separate copy is passed across, which doesn't allow sharing data between
    # create method and form hooks.
      doc: -> @doc
      formTitle: ->
        collectionName = Collections.getTitle(formArgs.collection)
        (if @doc then 'Edit' else 'Create') + ' ' + Strings.singular(collectionName)
      formType: ->
        type = formArgs.type
        return type if type
        if @doc then 'update' else 'insert'
      submitText: -> if @doc then 'Save' else 'Create'

    Form.events
      'click button.cancel': (e, template) ->
        e.preventDefault()
        console.debug 'onCancel', arguments, @
        formArgs.onCancel?(template)
        formTemplate = getTemplate(template)
        formTemplate.settings.onCancel?()

    Form.created = ->
      @settings = @data.settings ? {}
      formArgs.onCreate?.apply(@, arguments)

    Form.rendered = ->
      console.debug 'Rendered form', @, arguments
      # Move the buttons to the same level as the title and content to allow using flex-layout.
      $buttons = @$('.crud.buttons')
      $crudForm = @$('.flex-panel:first')
      if $buttons.length > 0 && $crudForm.length > 0
        $crudForm.append($buttons)
      @$('[type="submit"]', $buttons).click =>
        $form = $(@find('form', $crudForm))
        $form.submit()

      @schemaInputs = Forms.getSchemaInputs(@, formArgs.schema ? formArgs.collection)

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
        $label = Forms.getInputLabel($input)
        units = field.units
        $labelContent = $('<div class="value">' + $label.html() + '</div>')
        $label.empty()
        $label.append($labelContent)
        if units?
          formattedUnits = Strings.format.scripts(units)
          $units = $('<div class="units">' + formattedUnits + '</div>')
          $label.append($units)
        required = field.optional != true
        if required
          Forms.addRequiredLabel($label)
          hasRequiredField = true

      if hasRequiredField
        @$('.ui.form.segment').append($('<div class="footer"><div class="required"></div>Required field</div>'))

      addPopups = ->
        $(popupInputs).each ->
          $popupInput = $(@)
          # Manual control over popup to prevent losing focus when closing it in Semantic-UI 1.0.
          $popupInput.popup(
            {delay: 200, duration: 100, on: 'manual', content: $popupInput.data('desc')})
          isHovering = false
          handle = null
          $popupInput.on 'mouseenter', ->
            isHovering = true
            if handle
              clearTimeout(handle)
            handle = setTimeout(
              -> $popupInput.popup('show') if isHovering
              500)
          $popupInput.on 'mouseleave', ->
            isHovering = false
            isFocused = $popupInput.is(':focus')
            $popupInput.popup('hide')
            $popupInput.focus() if isFocused

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

    getTemplate = Form.getTemplate = (template) -> Templates.getNamedInstance(name, template)

    Form.getElement = -> getTemplate().$('form:first')
    Form.getFieldElement = (name) -> Forms.getFieldElement(name, Form.getElement())

    return Form

  addRequiredLabel: ($label) ->
    $requiredContent = $('<div class="required"></div>')
    $label.append($requiredContent)

  getRequiredLabels: ($em) -> $('.required', $em)

  getInputLabel: ($input) ->
    $label = $input.prev('label')
    if $label.length == 0
      $parent = $input.parent()
      if $parent.is('.dropdown')
        $label = $parent.prev('label')
    $label

  setInputValue: ($input, value) ->
    if @isSelectInput($input)
      @setSelectValue($input, value)
    else if $input.is('[type="checkbox"]')
      $input.prop('checked', value)
    else
      $input.val(value)

  getInputValue: ($input) ->
    if @isSelectInput($input)
      @getSelectValue($input)
    else
      $input.val()

  getFieldElement: (name, formElement) -> $('[data-schema-key="' + name + '"]', formElement)

  isSelectInput: ($input) -> $input.is('select') || @isDropdown($input)

  getSelectOption: ($input, value) ->
    if @isDropdown($input)
      Template.dropdown.getItem($input, value)
    else if @isSelectInput($input)
      $('option[value="' + value + '"]', $input)
    else
      throw new Error('No select field found.')

  setSelectValue: ($input, value) ->
    if @isDropdown($input)
      Template.dropdown.setValue($input, value)
    else
      $input.val(value)
  
  getSelectValue: ($input) ->
    if @isDropdown($input)
      Template.dropdown.getValue($input)
    else
      $input.val()

  isDropdown: ($input) -> Template.dropdown.isDropdown($input)

# We may pass the temporary collection as an attribute to autoform templates, so we need to
# define this to avoid errors since it is passed into the actual <form> HTML object.
  preventText: (obj) ->
    obj.toText = -> ''
    obj

  findFieldInput: (template, name) ->
    template.find('[name="' + name + '"]')

  getSchemaInputs: (template, arg) ->
    $schemaInputs = template.$('[data-schema-key]')
    schema = Collections.getSchema(arg)
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
