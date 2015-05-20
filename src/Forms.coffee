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
        template = getTemplate(@template)
        onSubmit = formArgs.onSubmit ? formArgs.hooks?.onSubmit
        result = onSubmit?.apply(@, args)
        callback = => template.settings.onSubmit?.apply(@, args)
        deferCallback(result, callback)
        # Perform logic for submitting bulk forms.
        if Form.isBulk(template)
          Form.submitBulkForm(insertDoc, updateDoc, currentDoc, @, template)
        # If no result is provided, prevent the form submission from refreshing the page.
        return (result ? false)

      onSuccess: (operation, result) ->
        args = arguments
        template = getTemplate(@template)
        Form.updateDocs(template)
        Form.setUpDocs(template)
        onSuccess = formArgs.onSuccess ? formArgs.hooks?.onSuccess
        result = onSuccess?.apply(@, args)
        callback = => template.settings.onSuccess?.apply(@, args)
        deferCallback(result, callback)

      before:
        # Remove fields in the modifiers which haven't been changed.
        update: (modifier) ->
          $input = $(@autoSaveChangedElement)
          changes = Form.getDocChanges(@template)
          _.each ['$set', '$unset'], (propName) ->
            fields = modifier[propName]
            if fields?
              _.each fields, (value, key) ->
                unless changes[key]? then delete fields[key]
          modifier

      onError: (operation, error) ->
        template = getTemplate(@template)
        Logger.error('Error submitting form', operation, error, template)
        onError = formArgs.onError ? formArgs.hooks?.onError
        onError?.apply(@, args)
        throw new Error(error)

      beginSubmit: ->
        template = getTemplate(@template)
        template.isSubmitting = true
        Form.setSubmitButtonDisabled(true, template)

      endSubmit: ->
        template = getTemplate(@template)
        template.isSubmitting = false
        Form.setSubmitButtonDisabled(false, template)

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
      doc: -> Tracker.nonreactive -> Form.getValues()
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
      resetOnSuccess: -> formArgs.resetOnSuccess ? false

    ################################################################################################
    # EVENTS
    ################################################################################################

    Form.events
      'click button.cancel': (e, template) ->
        e.preventDefault()
        formArgs.onCancel?(template)
        formTemplate = getTemplate(template)
        formTemplate.settings.onCancel?()

    ################################################################################################
    # LIFECYCLE
    ################################################################################################

    origCreated = Form.created
    Form.created = ->
      origCreated?()
      @settings = @data.settings ? {}
      Form.setUpDocs(@)
      @isSubmitting = false
      formArgs.onCreate?.apply(@, arguments)

    origRendered = Form.rendered
    Form.rendered = ->
      origRendered?()
      # Move the buttons to the same level as the title and content to allow using flex-layout.
      $buttons = @$('.crud.buttons')
      $crudForm = @$('.flex-panel:first')
      $form = Forms.getFormElement(@)
      if $buttons.length > 0 && $crudForm.length > 0
        $crudForm.append($buttons)
      # If the submit button is outside the form, it won't be captured by AutoForm, so bind an
      # event manually.
      $submit = Form.getSubmitButton(@)
      if $submit.closest('form').length == 0
        $submit.click => $form.submit()

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

      if Form.isReactive()
        Form.setUpReactivity()

      if @data.docPromise?
        Q.when(@data.docPromise).then => Form.mergeLatestDoc(@)
      
      formArgs.onRender?.apply(@, arguments)

    oldDestroyed = Form.destroyed
    Form.destroyed = ->
      oldDestroyed?()
      template = @
      template.isDestroyed = true
      formArgs.onDestroy?.apply(@, arguments)

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

    Form.getBulkValues = (template, docs) ->
      values = {}
      template = getTemplate(template)
      docs ?= Form.getDocs(template)
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

    # Form.setUpBulkFields = (template) ->
    #   template = getTemplate(template)
    #   values = Form.getBulkValues()
    #   schemaInputs = Form.getSchemaInputs(template)
    #   _.each schemaInputs, (input, key) ->
    #     $input = $(input.node)
    #     value = Objects.getModifierProperty(values, key)
    #     if Setter.isDefined(value)
    #       placeholder = ''
    #     else

    #     $input.attr('placeholder', placeholder)

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

    ################################################################################################
    # REACTIVE UPDATES
    ################################################################################################

    Form.isReactive = -> !!formArgs.reactive

    Form.setUpReactivity = (template) ->
      template = getTemplate(template)
      docs = Form.getDocs()
      # If no docs exist, no reactive updates can occur on them.
      return unless docs.length > 0
      docIdMap = {}
      _.each docs, (doc) -> docIdMap[doc._id] = true
      collection = Form.getCollection()
      singularName = Form.getSingularName()
      # Check if the doc has changed and ensure the current form is not submitting to prevent
      # self-detection.
      docHasChanged = (doc) -> docIdMap[doc._id]?# && !template.isSubmitting
      template.autorun ->
        Collections.observe collection,
          changed: (doc) ->
            return unless docHasChanged(doc)
            merge = true
            if formArgs.reactiveAutoMerge == false
              merge = confirm('The ' + singularName + ' being edited by this form has been
                  modified. Do you want to merge changes?')
            if merge then Form.mergeLatestDoc(template)
          deleted: (doc) ->
            return unless docHasChanged(doc)
            alert('The ' + singularName + ' being edited by this form has been removed.')
            # TODO(aramk) Change the form to insert.

    ################################################################################################
    # AUXILIARY
    ################################################################################################

    Form.setUpDocs = (template) ->
      template = getTemplate(template)
      data = template.data
      template.docs = Form.parseDocs(template)
      data.doc = Form.getValues(template)
      template.origDoc = Setter.clone(data.doc)

    Form.updateDocs = (template) ->
      template = getTemplate(template)
      data = template.data
      docs = _.map template.docs, (doc) -> Form.getCollection().findOne(doc._id)
      template.docs = docs
      data.doc = Form.getValues(template)
      if data.docs?
        data.docs = docs

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
      collectionName = Collections.getTitle(Form.getCollection())
      singularName = Form.getSingularName()
      docs = Form.getDocs()
      suffix = Strings.pluralize(singularName, docs.length, collectionName)
      suffix = Strings.toTitleCase(suffix)
      if Form.isBulk()
        suffix = docs.length + ' ' + suffix
      (if docs.length > 0 then 'Edit' else 'Create') + ' ' + suffix

    Form.getCollection = -> Collections.get(formArgs.collection)

    Form.getSchema = -> Collections.getSchema(formArgs.schema ? Form.getCollection())

    getTemplate = Form.getTemplate = (template) -> Templates.getNamedInstance(name, template)

    Form.getElement = (template) -> Forms.getFormElement(getTemplate(template))

    Form.getFieldElement = (name, template) ->
      Forms.getFieldElement(name, Form.getElement(template), template)

    Form.getSchemaInputs = (template) ->
      template = getTemplate(template)
      Forms.getSchemaInputs(template, formArgs.schema ? Form.getCollection())

    Form.getValues = (template) ->
      if Form.isBulk(template)
        Form.getBulkValues(template)
      else
        Form.getDocs(template)[0] ? null

    # @returns {Object} The diff between the original document and the resulting document from
    #     the current state of the form.
    Form.getDocChanges = (template) ->
      template = getTemplate(template)
      formDoc = Form.getInputValues(template)
      origDoc = template.origDoc ? {}
      origDoc = Objects.flattenProperties(Setter.clone(origDoc))
      delete origDoc._id
      keys = _.intersection _.keys(formDoc), _.keys(origDoc)
      changes = {}
      _.each keys, (key) ->
        formValue = formDoc[key]
        origValue = origDoc[key]
        if formValue? && origValue? && formValue.toString().trim() != origValue.toString().trim()
          changes[key] = formValue
      changes

    # Merges the latest document into the form, giving precedence to the changed values in the form.
    # @returns {Object} The flattened properties of the latest document which were merged into the
    #     form.
    Form.mergeLatestDoc = (template) ->
      template = getTemplate(template)
      return unless Form.hasDoc(template)
      docs = Form.getDocs(template)
      changedValues = Form.getDocChanges(template)
      collection = Form.getCollection()
      latestDocs = []
      _.each docs, (doc) ->
        doc = collection.findOne(doc._id)
        if doc? then latestDocs.push(doc)
      latestValues = if docs.length > 0 then Form.getBulkValues(template, latestDocs) else docs[0]
      latestValues ?= {}
      latestValues = Objects.flattenProperties(latestValues)
      $form = Forms.getFormElement(template)
      mergedValues = {}
      _.each latestValues, (value, key) ->
        if !changedValues[key]? || changedValues[key].toString().trim() != value.toString().trim()
          $input = Forms.getFieldElement(key, $form)
          # Not all values in the document need to be included in the form. Only record those which
          # are.
          if Forms.setInputValue($input, value)
            mergedValues[key] = value
      mergedValues

    Form.getInputValues = (template) ->
      template = getTemplate(template)
      $inputs = Forms.getFieldElements(Forms.getFormElement(template))
      values = {}
      $inputs.each ->
        $input = $(@)
        id = Forms.getInputId($input)
        value = Forms.getInputValue($input)
        values[id] = value
      values

    Form.setSubmitButtonDisabled = (disabled, template) ->
      Form.getSubmitButton(template).toggleClass('disabled', !!disabled)

    Form.getSubmitButton = (template) ->
      $buttons = template.$('.crud.buttons')
      template.$('[type="submit"]', $buttons)

    Form.getSingularName = ->
      collectionName = formArgs.collectionName ? Collections.getTitle(Form.getCollection())
      singular = formArgs.singularName
      unless singular
        if collectionName
          singular = Strings.singular(collectionName)
        else
          return null
      singular.toLowerCase()

    # Return the Form to be used as a Template.
    return Form

  ##################################################################################################
  # STATICS
  ##################################################################################################

  addRequiredLabel: ($label) ->
    $requiredContent = $('<div class="required"></div>')
    $label.append($requiredContent)

  getRequiredLabels: ($em) -> $('.required', $em)

  getInputLabel: ($input) ->
    $label = $input.siblings('label')
    if $label.length == 0
      $parent = $input.parent()
      if $parent.is('.dropdown')
        $label = @getInputLabel($parent)
    $label

  # @param {jQuery} $input
  # @param {*} value
  # @returns {Boolean} Whether the given value was successfully applied to the given input element.
  #     This is false if the value is unchanged.
  setInputValue: ($input, value) ->
    changed = @getInputValue($input)
    return false if value == changed
    if @isSelectInput($input)
      @setSelectValue($input, value)
    else if @isCheckbox($input)
      $input.prop('checked', value)
    else
      $input.val(value)
    return true

  getInputValue: ($input) ->
    if @isSelectInput($input)
      @getSelectValue($input)
    else if @isCheckbox($input)
      $input.prop('checked')
    else
      $input.val()

  getInputId: ($input) -> $input.attr('data-schema-key')

  getFieldElement: (name, formElement) -> $('[data-schema-key="' + name + '"]:first', formElement)

  getFieldElements: (formElement) -> $('[data-schema-key]', formElement)

  getFormElement: (template) -> template.$('form:first')

  isSelectInput: ($input) -> $input.is('select') || @isDropdown($input)

  isCheckbox: ($input) -> $input.is('[type="checkbox"]')

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
