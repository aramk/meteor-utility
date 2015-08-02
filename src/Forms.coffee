Forms =

  defineModelForm: (formArgs) ->
    name = formArgs.name
    Form = Template[name]
    unless name
      throw new Error 'No name provided for form'
    unless Form
      throw new Error 'No template defined with name ' + name

    Form.getSettings = -> _.extend({}, formArgs)

    ################################################################################################
    # HOOKS
    ################################################################################################

    hooks =
      # Settings should be passed to the autoForm helper to ensure they are available in these
      # callbacks.
      onSubmit: (insertDoc, updateDoc, currentDoc) ->
        args = arguments
        template = getTemplate(@template)
        onSubmit = formArgs.onSubmit
        result = onSubmit?.apply(@, args)
        callback = => template.settings.onSubmit?.apply(@, args)
        deferCallback(result, callback)
        # Perform logic for submitting bulk forms.
        if Form.isBulk(template)
          Form.submitBulkForm(insertDoc, updateDoc, currentDoc, @, template)
        else if !onSubmit?
          # Ensure onSuccess() is called.
          @done()
        # If no result is provided, prevent the form submission from refreshing the page.
        return (result ? false)

      onSuccess: (operation, result) ->
        args = arguments
        template = getTemplate(@template)
        Form.updateDocs(template)
        Form.setUpDocs(template)
        onSuccess = formArgs.onSuccess
        successResult = onSuccess?.apply(@, args)
        callback = => template.settings.onSuccess?.apply(@, args)
        deferCallback(successResult, callback)

      before:
        update: (modifier) ->
          template = getTemplate(@template)
          # TODO(aramk) This won't run if we use Setter.merge() below to merge hooks and
          # this default hook is replaced by a particular form.

          # Prevent change events in the inputs during loading from submitting the form until
          # the doc promise is resolved and the form is considered loaded.
          return false if Q.isPending(Form.whenLoaded(template))

          # TODO(aramk) This can result in modifier being empty and fail during submission.
          # TODO(aramk) Sometimes form fields are skipped when retrieving their values.
          if formArgs.submitDiff
            # Remove fields in the modifiers which haven't been changed.
            # $input = $(@autoSaveChangedElement)
            changes = Form.getDocChanges(template)
            _.each ['$set', '$unset'], (propName) ->
              fields = modifier[propName]
              if fields?
                _.each fields, (value, key) ->
                  if changes[key] == undefined then delete fields[key]
          modifier

      onError: (operation, error) ->
        args = arguments
        template = getTemplate(@template)
        settings = template.settings
        unless formArgs.loggerNotify == false || settings.loggerNotify == false
          Logger.error(error.message)
        Logger.error('Form error', operation, error, template, {notify: false})
        onError = formArgs.onError
        onError?.apply(@, args)
        settings.onError?.apply(@, args)

      beginSubmit: ->
        template = getTemplate(@template)
        template.isSubmitting = true
        Form.setSubmitButtonDisabled(true, template)

      endSubmit: ->
        template = getTemplate(@template)
        template.isSubmitting = false
        Form.setSubmitButtonDisabled(false, template)

    Form.addHooks = ->
      if arguments.length == 1
        formId = name
        hooks = arguments[0]
      else if arguments.length == 2
        formId = arguments[0]
        hooks = arguments[1]
      else
        throw new Error('Invalid arguments')
      
      formToDoc = hooks.formToDoc
      # If `formToDocOnUpdate` is true, the `formToDoc` hook is used for both inserts and updates
      # (as in AutoForm < v5).
      if hooks.formToDocOnUpdate == true && formToDoc?
        hooks.formToModifier ?= (modifier) ->
          # If no document can be found, then this hook was fired when formType=null and no
          # doc existed. Hence an empty doc should be used to ensure the modifier can still be
          # applied and passed to formToDoc. NOTE: formToDoc would also have been called, but
          # we should not pass this modifier since it may not match the output of formToDoc if
          # changes were made. Use a temporary ID to ensure simulateModifierUpdate() can be called.
          doc = @template.data.doc ? {_id: 'tmp'}
          doc = Collections.simulateModifierUpdate(doc, modifier)
          delete doc._id
          doc = formToDoc.call(@, doc)
          modifier.$set = Objects.flattenProperties(doc)
          # Ensure keys in $set are not present in $unset.
          if modifier.$unset
            _.each modifier.$set, (value, key) -> delete modifier.$unset[key]
          delete modifier.$set._id
          modifier
      AutoForm.addHooks formId, hooks

    Setter.merge hooks, formArgs.hooks
    Form.addHooks(hooks)

    ################################################################################################
    # HELPERS
    ################################################################################################

    Form.helpers
      collection: -> Form.getCollection()
      schema: -> Tracker.nonreactive -> 
        if Form.isBulk()
          Form.getBulkSchema()
        else
          Form.getSchema()
      formName: -> name
      # Without this a separate copy is passed across, which doesn't allow sharing data between
      # create method and form hooks.
      doc: -> Tracker.nonreactive -> Form.getValues()
      formTitle: -> Tracker.nonreactive -> Form.getFormTitle()
      formType: -> Tracker.nonreactive -> 
        return if Form.isBulk()
        doc = Form.getDocs()[0]
        type = Form.getTemplate().settings.formType
        # Allow passing type = null to trigger onSubmit() hook.
        if type == undefined then type = formArgs.type
        if type == undefined then type = (if doc then 'update' else 'insert')
        type
      submitText: -> Tracker.nonreactive -> if Form.getDocs().length > 0 then 'Save' else 'Create'
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
      @settings = @data?.settings ? {}
      Form.setUpDocs(@)
      if Form.isReactive() then Form.setUpReactivity()
      @isSubmitting = false
      @loadDf = Q.defer()
      formArgs.onCreate?.apply(@, arguments)
      origCreated?.apply(@, arguments)

    origRendered = Form.rendered
    Form.rendered = ->
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
        $submit.click =>
          Logger.debug('Submitting form...', formArgs)
          $form.submit()
      origRendered?.apply(@, arguments)

      schemaInputs = Form.getSchemaInputs(@)
      popupInputs = []
      hasRequiredField = false
      _.each schemaInputs, (input, key) ->
        $input = $(input.node)
        if Forms.isCheckbox($input)
          # Ensure the tooltip is available on the label as well as the input.
          $input = $input.parent()
        field = input.field
        desc = field.desc ? field.description
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

      Form.setUpFields(@)

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

      resolveFormLoaded = => 
        # Set a delayed promise for loading the form to prevent submissions before the delay due
        # to change events fired from the dropdown.
        _.delay =>
          Logger.debug('Loaded form', formArgs.name)
          @loadDf.resolve(docPromise)
        , formArgs.loadDelay ? 1000

      if @data?.docPromise?
        docPromise = Q.when(@data.docPromise)
        docPromise.then =>
          # Ensure all documents are loaded if they weren't available until the docPromise was
          # resolved.
          Form.setUpDocs(@)
          Form.updateDocs(@)
          Form.mergeLatestDoc(@)
          resolveFormLoaded()
      else
        resolveFormLoaded()
      
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

    Form.getDocs = (template) ->
        _.filter _.values(getTemplate(template).docs.get()), (value) -> value?

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
      Form.setUpFields(template)

    Form.getBulkValues = (template, docs) ->
      values = {}
      template = getTemplate(template)
      docs ?= Form.getDocs(template)
      otherDocs = docs.slice(1)
      if _.isEmpty(otherDocs)
        throw new Error('At least 2 documents are needed for bulk values.')
      getValue = (doc, key) -> Objects.getModifierProperty(doc, key)
      # Populate all form fields with any common values across docs if possible.
      fields = Collections.getFields(Form.getCollection())
      _.each fields, (field, fieldId) ->
        commonValue = getValue(docs[0], fieldId)
        hasCommonValue = _.all otherDocs, (doc) -> commonValue == getValue(doc, fieldId)
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
      # Ensure the latest version of the doc is stored in data.doc.
      Form.updateDocs(template)
      docs = template.docs.get()
      docIds = _.keys(docs)
      doc = docs[docIds[0]]
      template.reactiveDoc = new ReactiveVar(doc)
      template.getReactiveDoc = Form.getReactiveDoc.bind(template)
      # If no docs exist, no reactive updates can occur on them.
      return unless docIds.length > 0
      collection = Form.getCollection()
      singularName = Form.getSingularName()
      _updateDocs = ->
        Form.updateDocs(template)
        template.reactiveDoc.set(template.data?.doc)
      updateDocs = _.debounce _updateDocs, 500
      # Check if the doc has changed and ensure the current form is not submitting to prevent
      # self-detection.
      template.autorun ->
        Collections.observe collection.find(_id: {$in: docIds}),
          changed: (doc) ->
            merge = true
            if formArgs.reactiveAutoMerge == false
              merge = confirm('The ' + singularName + ' being edited by this form has been
                  modified. Do you want to merge changes?')
            if merge then Form.mergeLatestDoc(template)
            updateDocs()
          deleted: (doc) ->
            alert('The ' + singularName + ' being edited by this form has been removed.')
            updateDocs()
            # TODO(aramk) Change the form to insert.

    Form.getReactiveDoc = (template) -> Form.getTemplate(template).reactiveDoc.get()

    ################################################################################################
    # AUXILIARY
    ################################################################################################

    updateDataDocs = (template) ->
      data = template.data ?= {}
      doc = Form.getValues(template)
      if doc? then data.doc = doc
      docs = template.docs.get()
      if data.docs? then data.docs = _.keys(docs)

    Form.setUpDocs = (template) ->
      template = getTemplate(template)
      docs = Form.parseDocs(template)
      template.docs ?= new ReactiveVar({})
      template.docs.set(docs)
      updateDataDocs(template)

    Form.updateDocs = (template) ->
      collection = Form.getCollection()
      return unless collection
      template = getTemplate(template)
      data = template.data ? {}
      docs = template.docs.get()
      _.each docs, (doc, docId) ->
        docs[docId] = collection.findOne(_id: docId)
      template.docs.set(docs)
      updateDataDocs(template)

    Form.parseDocs = (template) ->
      template = getTemplate(template)
      data = template.data ? {}
      if template.docs?
        docs = _.keys(template.docs.get())
      else if data.docs?
        docs = data.docs
      else if data.doc?
        docs = [data.doc]
      else
        docs = []
      parsedDocs = {}
      _.each docs, (doc) ->
        if Types.isString(doc)
          docId = doc
          doc = Form.getCollection().findOne(docId)
        else
          docId = doc._id
        parsedDocs[docId] = doc
      parsedDocs

    Form.setUpFields = (template) ->
      template = getTemplate(template)
      schemaInputs = Form.getSchemaInputs(template)
      _.each schemaInputs, (input, key) ->
        # Round float fields to 2 decimal places.
        $input = $(input.node)
        field = input.field
        if field.type == Number && field.decimal && formArgs.roundFloats
          decimals = field.decimals ? 2
          value = parseFloat Forms.getInputValue($input)
          return unless Numbers.isDefined(value)
          value = value.toFixed(2)
          Forms.setInputValue($input, value)
      template.formDoc = Form.getInputValues(template)

    Form.getFormTitle = ->
      collectionName = Collections.getTitle(Form.getCollection())
      singularName = Form.getSingularName()
      docs = Form.getDocs()
      if docs.length > 0
        suffix = Strings.pluralize(singularName, docs.length, collectionName)
      else
        suffix = singularName
      suffix = Strings.toTitleCase(suffix)
      if Form.isBulk()
        suffix = docs.length + ' ' + suffix
      (if docs.length > 0 then 'Edit' else 'Create') + ' ' + suffix

    Form.getCollection = -> Collections.get(formArgs.collection)

    Form.getSchema = -> Collections.getSchema(formArgs.schema ? Form.getCollection())

    getTemplate = Form.getTemplate = (template) -> Templates.getNamedInstance(name, template)

    Form.getElement = (template) -> Forms.getFormElement(getTemplate(template))

    Form.getFieldElements = (template) -> Forms.getFieldElements(Form.getElement(template))

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
      prevFormDoc = template.formDoc ? {}
      # Form doc is the full set of fields which the doc supports. We must avoid creating modifiers
      # containing any other fields, since this form does not affect them.
      keys = _.keys(formDoc)
      changes = {}
      _.each keys, (key) ->
        formValue = Forms._sanitizeCompareValue(formDoc[key])
        prevValue = Forms._sanitizeCompareValue(prevFormDoc[key])
        if formValue != prevValue
          # Ensure empty values are null.
          changes[key] = formValue || null
      changes

    # Merges the latest document into the form, giving precedence to the changed values in the form.
    # @returns {Object} The flattened properties of the latest document which were merged into the
    #     form.
    Form.mergeLatestDoc = (template) ->
      template = getTemplate(template)
      return unless Form.hasDoc(template)
      docs = Form.getDocs(template)
      changedValues = Form.getDocChanges(template)
      changedValuesKeyMap = {}
      _.each changedValues, (value, key) -> changedValuesKeyMap[key] = true
      collection = Form.getCollection()
      latestDocs = []
      _.each docs, (doc) ->
        doc = collection.findOne(doc._id)
        if doc? then latestDocs.push(doc)
      latestValues =
        if docs.length > 1 then Form.getBulkValues(template, latestDocs) else latestDocs[0]
      latestValues ?= {}
      latestValues = Objects.flattenProperties(latestValues)
      mergedValues = {}
      _.each Form.getSchemaInputs(template), (input, key) ->
        $input = $(input.node)
        value = latestValues[key]
        # Update the form values to the latest doc values if the user has not changed them since the
        # last merge.
        if !changedValuesKeyMap[key]?
          # Not all values in the document need to be included in the form. Only record those which
          # are.
          if Forms.setInputValue($input, value) then mergedValues[key] = value
      Form.setUpFields(template)
      mergedValues

    Form.getInputValues = (template) ->
      template = getTemplate(template)
      $inputs = Form.getFieldElements(template)
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
      template = getTemplate(template)
      $form = Forms.getFormElement(template)
      template.$('[type="submit"]', $form)

    Form.getSingularName = ->
      collectionName = formArgs.collectionName ? Collections.getTitle(Form.getCollection())
      singular = formArgs.singularName
      unless singular
        if collectionName
          singular = Strings.singular(collectionName)
        else
          return null
      singular.toLowerCase()

    Form.whenLoaded = (template) -> getTemplate(template).loadDf.promise

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
    oldValue = @getInputValue($input)
    isChanged = Forms._sanitizeCompareValue(value) != Forms._sanitizeCompareValue(oldValue)
    return false unless isChanged
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
    else if @isDropdown($input)
      Template.dropdown.getValue($input)
    else if @isCheckbox($input)
      $input.prop('checked')
    else
      $input.val()

  setInputDisabled: ($input, disabled) ->
    disabled = disabled == true
    if Forms.isDropdown($input)
      $dropdown = $input.closest('.ui.dropdown')
      $dropdown.toggleClass('disabled', disabled)
    else
      $input.prop('readonly', disabled)

  _sanitizeCompareValue: (value) -> value?.toString().trim() ? ''

  getInputId: ($input) -> $input.attr('data-schema-key')

  getFieldElement: (name, formElement) -> $('[data-schema-key="' + name + '"]:first', formElement)

  getFieldElements: (formElement) ->
    # Exclude fields in sub-forms, since they will belong to a different AutoForm and schema.
    $('[data-schema-key]', formElement).not $('form [data-schema-key]', formElement)

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

  isDropdown: ($input) -> Template.dropdown?.isDropdown($input) ? false

  # We may pass the temporary collection as an attribute to autoform templates, so we need to
  # define this to avoid errors since it is passed into the actual <form> HTML object.
  preventText: (obj) ->
    obj.toText = -> ''
    obj

  findFieldInput: (template, name) ->
    template.find('[name="' + name + '"]')

  getSchemaInputs: (template, arg) ->
    formElement = Forms.getFormElement(template)
    $schemaInputs = Forms.getFieldElements(formElement)
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
  # Defer the callback if the result is a promise. Otherwise execute
  # callback immediately.
  if result?.then
    result.then -> callback()
  else
    callback()
