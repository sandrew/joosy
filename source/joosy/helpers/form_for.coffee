Joosy.helpers 'Application', ->

  @formFor = (resource, options={}, block=false) ->
    if typeof options == "function"
      block   = options
      options = {}

    attributes = options.html || {}
    attributes.action ||= options.url
    delete options.html
    delete options.url

    formBuilder = new Joosy.Helpers.FormBuilder(@, [resource], options)
    attributes.id = formBuilder.__id

    @contentTag 'form', block?.call(@, formBuilder), attributes

#
# @nodoc
#
class Joosy.Helpers.FormBuilder
  constructor: (@__template, @__resources, @__options) ->
    @__id       = Joosy.uid()
    @__buckets  = {}
    @__resource = @__resources[@__resources.length-1]

    if @__resource.get && @__resource.set && @__resource.bind
      @__template.onRendered =>
        form = document.getElementById(@__id)
        return unless form?

        for input in form.elements
          continue unless input.name? && input.name.length > 0 && input.getAttribute('data-form') == @__id

          do (input) =>
            @__buckets[input.name] ||= []
            @__buckets[input.name].push input

            input.addEventListener 'change', (
              (ev) => @__inputToResource input
            ), false

        @__binding = @__resource.bind 'changed', =>
          @__formFromResource()

      @__template.onRemoved =>
        if @__binding?
          @__resource.unbind @__binding
          delete @__binding

  #
  # Global helpers
  #
  __withInheritedOptions: (inputOptions) ->
    options = Joosy.Module.merge {}, @__options
    Joosy.Module.merge options, inputOptions
    options

  __stabilize: (block) ->
    return if @__unstable

    @__unstable = true
    try
      block()
    finally
      delete @__unstable

  #
  # Synchronization helpers
  #
  __isCheckOrRadioBox: (input) ->
    input instanceof HTMLInputElement && (input.type == 'checkbox' || input.type == 'radio')

  __activateGroupInput: (input) ->
    if @__isCheckOrRadioBox(input)
      input.checked = true

  __deactivateGroupInput: (input) ->
    if @__isCheckOrRadioBox(input)
      input.checked = false

  __isGroupInputActive: (input) ->
    if @__isCheckOrRadioBox(input)
      input.checked
    else
      true

  __inputToResource: (input) ->
    @__stabilize =>
      if @__isCheckOrRadioBox(input)
        for neighbor in @__buckets[input.name]
          if @__isGroupInputActive(neighbor)
            value = neighbor.value
      else
        value = input.value

      # Type casting
      value = switch input.type
        when 'checkbox'
          value != '0'
        else
          value

      @__resource.set input.getAttribute('data-to'), value

  __formFromResource: ->
    @__stabilize =>
      for name, inputs of @__buckets
        value = @__resource.get inputs[0].getAttribute('data-to')

        # Type casting
        value = switch inputs[0].type
          when 'checkbox'
            if value
              '1'
            else
              '0'
          else
            value

        for input in inputs
          if @__isCheckOrRadioBox(input)
            if input.value == value
              @__activateGroupInput input
            else
              @__deactivateGroupInput input
          else
            input.value = value

  #
  # Builder helpers
  #
  __generateId: (property, suffix) ->
    resourceName = @__resource.__entityName || @_resource.toString()
    resourceId   = @__resource.id?()

    parameterizedProperty =
      property.replace(/[^a-z0-9\-_]+/gi, '_')
              .replace(/^_+|_+$|(_)_+/g, '$1')
              .toLowerCase()

    id = resourceName
    id = "#{@__options.namespace}_#{id}" if @__options.namespace?.length > 0
    id += "_#{resourceId}" if resourceId?
    id += "_#{parameterizedProperty}"
    id += "_#{suffix}" if suffix?.length > 0

    id

  __generateInput: (type, property, attributes={}, value=undefined, suffix = '') ->
    attributes.type         = type
    attributes.id           = @__generateId property, suffix
    attributes.name         = property
    attributes.value        = value if value?
    attributes['data-to']   = property
    attributes['data-form'] = @__id

    @__template.tag 'input', attributes

  #
  # Methods
  #
  fieldsFor: (resource, options={}, block) ->
    if typeof options == 'function'
      block = options
      options = {}

    fieldBuilder = new FormBuilder @__template, @__resources.concat(resource), @__withInheritedOptions(options)

    @__template.contentTag 'fieldset', {id: fieldBuilder.__id}, =>
      block.call @__template, fieldBuilder

  label: (property, attributes={}, content='') ->
    if typeof attributes == 'string' || typeof attributes == 'function'
      content = attributes
      attributes = {}

    attributes.for = @__generateId property

    if typeof content == 'function'
      @__template.contentTag 'label', attributes, content
    else
      @__template.contentTag 'label', content, attributes

  for type in [ 'text', 'file', 'hidden', 'password' ]
    do (type) =>
      @::[type + 'Field'] = (property, attributes={}) ->
        attributes.value ||= @__resource.get(property)

        @__generateInput type, property, attributes

  radioButton: (property, tagValue, attributes={}) ->
    if @__resource.get(property) == tagValue
      attributes.checked = 'checked'

    @__generateInput 'radio', property, attributes, tagValue

  textArea: (property, attributes={}) ->
    value   = attributes.value
    value ||= @__resource.get(property)

    delete attributes.value

    attributes.id           = @__generateId property
    attributes.name         = property
    attributes['data-to']   = property
    attributes['data-form'] = @__id

    @__template.contentTag 'textarea', value, attributes

  checkBox: (property, attributes={}, checkedValue="1", uncheckedValue="0") ->
    attributes.checked = 'checked' if @__resource.get(property)

    hidden = @__generateInput 'hidden', property, attributes, uncheckedValue, 'default'
    hidden + @__generateInput('checkbox', property, attributes, checkedValue)

  select: (property, selectOptions={}, attributes={}) ->
    value   = attributes.value
    blank   = attributes.includeBlank
    value ||= @__resource.get(property)

    delete attributes.value
    delete attributes.includeBlank

    optionArray = []
    if selectOptions instanceof Array
      optionArray = selectOptions.slice(0)
    else
      optionArray = []
      for key, value of selectOptions
        optionArray.push [ value, key ]

    optionArray.push [ '', '' ] if blank

    optionsHtml = ''

    for option in optionArray
      optionAttributes = {}

      if option instanceof Array
        content = option[0]
        optionAttributes.value = option[1]
      else
        content = option
        optionAttributes.value = option

      if value? && optionAttributes.value == value
        optionAttributes.selected = 'selected'

      optionsHtml += @__template.contentTag 'option', content, optionAttributes

    attributes.id           = @__generateId property
    attributes.name         = property
    attributes['data-to']   = property
    attributes['data-form'] = @__id

    @__template.contentTag 'select', optionsHtml, attributes