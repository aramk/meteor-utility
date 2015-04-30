Forms =

  FIELD_SELECTOR: '.form-group',

  defineModelForm: (formArgs) ->
    name = formArgs.name
    Form = Template[name]
    unless Form
      throw new Error 'No template defined with name ' + name

    ################################################################################################
    # HOOKS
    ################################################################################################

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
        # Perform logic for submitting bulk forms.
        if Form.isBulk(template)
          Form.submitBulkForm(insertDoc, updateDoc, currentDoc, @, template)
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

      beginSubmit: (formId, template) -> Form.setSubmitButtonDisabled(true, template)

      endSubmit: (formId, template) -> Form.setSubmitButtonDisabled(false, template)

    if formArgs.hooks?
      AutoForm.addHooks name, formArgs.hooks

    ################################################################################################
    # HELPERS
    ################################################################################################

    Form.helpers
      collection: -> Form.getCollection()
      schema: ->
        if Form.isBulk()
          Form.getBulkSchema()
        else
          Form.getSchema()
      formName: -> name
      # Without this a separate copy is passed across, which doesn't allow sharing data between
      # create method and form hooks.
      doc: -> Form.getValues()
      formTitle: -> Form.getFormTitle()
      formType: ->
        return if Form.isBulk()
        doc = Form.getDocs()[0]
        type = formArgs.type
        return type if type
        if doc then 'update' else 'insert'
      submitText: -> if Form.getDocs().length > 0 then 'Save' else 'Create'
      hasDoc: -> Form.hasDoc()
      isBulk: -> Form.isBulk()
      autosave: -> formArgs.autosave

    ################################################################################################
    # EVENTS
    ################################################################################################

    Form.events
      'click button.cancel': (e, template) ->
        e.preventDefault()
        console.debug 'onCancel', arguments, @
        formArgs.onCancel?(template)
        formTemplate = getTemplate(template)
        formTemplate.settings.onCancel?()

    ################################################################################################
    # LIFECYCLE
    ################################################################################################

    Form.created = ->
      @settings = @data.settings ? {}
      @docs = Form.parseDocs()
      @data.doc = Form.getValues()
      formArgs.onCreate?.apply(@, arguments)

    Form.rendered = ->
      console.debug 'Rendered form', @, arguments
      # Move the buttons to the same level as the title and content to allow using flex-layout.
      $buttons = @$('.crud.buttons')
      $crudForm = @$('.flex-panel:first')
      $form = Forms.getFormElement(@)
      if $buttons.length > 0 && $crudForm.length > 0
        $crudForm.append($buttons)
      Form.getSubmitButton(@).click => $form.submit()

      schemaInputs = Form.getSchemaInputs()

      popupInputs = []
      hasRequiredField = false
      _.each schemaInputs, (input, key) ->
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
        return unless supportsPopups()
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
        return unless supportsPopups()
        $(popupInputs).popup('destroy')

      supportsPopups = -> $.fn.popup?

      @autorun (c) ->
        helpMode = Session.get 'helpMode'
        if helpMode then addPopups() else removePopups()

      # if Form.isBulk()
      #   Form.setUpBulkFields()
      
      formArgs.onRender?.apply(@, arguments)

    Form.destroyed = ->
      console.debug 'Destroyed form', @, arguments
      template = @
      template.isDestroyed = true
      formArgs.onDestroy?.apply(@, arguments)

    ################################################################################################
    # AUXILIARY
    ################################################################################################

    Form.parseDocs = (template) ->
      template = getTemplate(template)
      data = template.data
      if data.docs?
        docs = data.docs
      else if data.doc?
        docs = [data.doc]
      else
        docs = []
      _.map docs, (doc) ->
        if Types.isString(doc)
          Form.getCollection().findOne(doc)
        else
          doc

    Form.getFormTitle = ->
      collectionName = Collections.getTitle(formArgs.collection)
      docs = Form.getDocs()
      suffix = Strings.pluralize(Strings.singular(collectionName), docs.length, collectionName)
      if Form.isBulk()
        suffix = docs.length + ' ' + suffix
      (if docs.length > 0 then 'Edit' else 'Create') + ' ' + suffix

    Form.getCollection = -> Collections.get(formArgs.collection)

    Form.getSchema = -> Collections.getSchema(formArgs.schema ? Form.getCollection())

    ################################################################################################
    # AUXILIARY
    ################################################################################################

    getTemplate = Form.getTemplate = (template) -> Templates.getNamedInstance(name, template)

    Form.getElement = (template) -> Forms.getFormElement(getTemplate(template))

    Form.getFieldElement = (name, template) ->
      Forms.getFieldElement(name, Form.getElement(), template)

    Form.getSchemaInputs = (template) ->
      template = getTemplate(template)
      Forms.getSchemaInputs(template, formArgs.schema ? formArgs.collection)

    Form.getValues = (template) ->
      if Form.isBulk(template)
        Form.getBulkValues(template)
      else
        Form.getDocs(template)[0] ? null

    Form.setSubmitButtonDisabled = (disabled, template) ->
      Form.getSubmitButton(template).toggleClass('disabled', !!disabled)

    Form.getSubmitButton = (template) ->
      $buttons = template.$('.crud.buttons')
      template.$('[type="submit"]', $buttons)

    ################################################################################################
    # BULK EDITING
    ################################################################################################

    Form.getDocs = (template) -> getTemplate(template).docs

    Form.hasDoc = (template) -> Form.getDocs(template).length > 0
    
    Form.isBulk = (template) -> Form.getDocs(template).length > 1
    
    Form.clearFieldValues = (template) ->
      template = getTemplate(template)
      schemaInputs = Form.getSchemaInputs(template)
      _.each schemaInputs, (input, key) ->
        $input = $(input.node)
        Forms.setInputValue($input, null)

    Form.setFieldValues = (template, values) ->
      template = getTemplate(template)
      $form = Forms.getFormElement(template)
      _.each values, (value, key) ->
        $input = Forms.getFieldElement(key, $form)
        Forms.setInputValue($input, value)

    Form.getBulkValues = (template) ->
      values = {}
      template = getTemplate(template)
      docs = Form.getDocs(template)
      otherDocs = docs.slice(1)
      getValue = (doc, key) -> Objects.getModifierProperty(doc, key)
      # Populate all form fields with any common values across docs if possible.
      fields = Collections.getFields(Form.getCollection())
      _.each fields, (field, fieldId) ->
        commonValue = getValue(docs[0], fieldId)
        hasCommonValue = _.all otherDocs, (doc) ->
          commonValue == getValue(doc, fieldId)
        if hasCommonValue && commonValue?
          Objects.setModifierProperty(values, fieldId, commonValue)
      values

    Form.submitBulkForm = (insertDoc, updateDoc, currentDoc, context, template) ->
      template = getTemplate(template)
      oldValues = Form.getBulkValues(template)
      # TODO(aramk) if values are not present in insertDoc but are in oldValues then put them in
      # $unset.
      flatOldValues = Objects.flattenProperties(oldValues)
      flatNewValues = Objects.flattenProperties(insertDoc)
      # Only keep the fields which exist in the form so any values which exist in the doc but don't
      # exist as inputs are not removed.
      _.each flatOldValues, (value, key) ->
        unless Form.getFieldElement(key, template).length > 0
          delete flatOldValues[key]
      $unset = {}
      $set = flatNewValues
      modifier = {}
      _.each flatOldValues, (value, key) ->
        if flatNewValues[key]?
          if flatNewValues[key] == flatOldValues[key]
            delete flatNewValues[key]
        else
          $unset[key] = null
      if Object.keys($set).length > 0
        modifier.$set = $set
      if Object.keys($unset).length > 0
        modifier.$unset = $unset
      promises = []
      _.each Form.getDocs(template), (doc) ->
        df = Q.defer()
        promises.push(df.promise)
        Form.getCollection().update doc._id, modifier, (err, result) ->
          if err then df.reject(err) else df.resolve(result)
      Q.all(promises).then(
        -> context.done()
        (err) -> context.done(err)
      )
      # Prevent submission since it's asynchronous.
      return false

    Form.getBulkSchema = (template) ->
      # Create a copy of the schema with all fields as optional to allow submitting a partial
      # set of values.
      template = getTemplate(template)
      schema = Form.getSchema(template)
      schemaArgs = Setter.clone(schema._schema)
      _.each schemaArgs, (field, fieldId) ->
        field.optional = true
      new SimpleSchema(schemaArgs)

    Form.setUpBulkFields = (template) ->
      template = getTemplate(template)
      values = Form.getBulkValues()
      schemaInputs = Form.getSchemaInputs(template)
      _.each schemaInputs, (input, key) ->
        $input = $(input.node)
        value = Objects.getModifierProperty(values, key)
        if Setter.isDefined(value)
          placeholder = ''
        else

        $input.attr('placeholder', placeholder)

    Form.getSampleValues = (paramId, template) ->
      template = getTemplate(template)
      docs = Form.getDocs()
      values = []
      count = 0
      _.some docs, (doc) ->
        value = Objects.getModifierProperty(doc, paramId)
        if Setter.isDefined(value)
          values.push(value)
          count++
        return count >= 3

    return Form

  ##################################################################################################
  # STATICS
  ##################################################################################################

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

  getFormElement: (template) -> template.$('form:first')

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

####################################################################################################
# MISC AUXILIARY
####################################################################################################

deferCallback = (result, callback) ->
  # Defer the callback if the result is a promise. Ignore if result is false. Otherwise execute
  # callback immediately.
  unless result == false
    if result?.then
      result.then -> callback()
    else
      callback()
