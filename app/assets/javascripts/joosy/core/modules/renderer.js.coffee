#= require_tree ../templaters
#= require metamorph

Joosy.Modules.Renderer =

  __renderer: ->
    throw new Error "#{@constructor.name} does not have an attached template"

  __helpers: null

  included: ->
    @view = (template) ->
      if Object.isFunction(template)
        @::__renderer = template
      else
        @::__renderer = (locals={}) ->
          @render(template, locals)

    @helpers = (helpers...) ->
      @::__helpers ||= []
      helpers.map (helper) =>
        module = Joosy.Helpers[helper]
        unless module
          throw new Error "Cannot find helper module #{helper}"

        @::__helpers.push module

      @::__helpers = @::__helpers.unique()

  __instantiateHelpers: ->
    unless @__helpersInstance
      @__helpersInstance = Joosy.Helpers.Application

      @__helpersInstance.render = =>
        @render(arguments...)
        
      @__helpersInstance.widget = (element, widget) =>
        @widgets ||= {}
        
        uuid    = Joosy.uuid()
        element = document.createElement(element)
        temp    = document.createElement("div")
        
        element.id     = uuid
        @widgets['#'+uuid] = widget

        temp.appendChild(element)
        temp.innerHTML

      if @__helpers
        for helper in @__helpers
          Object.merge @__helpersInstance, helper

    @__helpersInstance

  # If we do not have __proto__ available...
  __proxifyHelpers: (locals) ->
    if locals.hasOwnProperty '__proto__'
      locals.__proto__ = @__instantiateHelpers()

      locals
    else
      unless @__helpersProxyInstance
        @__helpersProxyInstance = (locals) ->
          Object.merge(this, locals)

        @__helpersProxyInstance.prototype = @__instantiateHelpers()

      new @__helpersProxyInstance(locals)

  render: (template, locals={}) ->
    isResource   = Joosy.Module.hasAncestor(locals.constructor, Joosy.Resource.Generic)
    isCollection = Joosy.Module.hasAncestor(locals.constructor, Joosy.Resource.GenericCollection)
    
    if Object.isString template
      if @__renderSection?
        template = Joosy.Application.templater.resolveTemplate @__renderSection(), template, this

      template = Joosy.Application.templater.buildView template
    else if !Object.isFunction(template)
      throw new Error "#{Joosy.Module.__className__ @}> template (maybe @view) does not look like a string or lambda"

    if !Object.isObject(locals) && !isResource && !isCollection
      throw new Error "#{Joosy.Module.__className__ @}> locals (maybe @data?) not in: dumb hash, Resource, Collection"

    # Small code dup due to the fact we sometimes 
    # actually CLONE object when proxying helpers
    if isCollection
      context  = @__proxifyHelpers {data: locals.data}
      morph    = Metamorph template(context)
      update   = => morph.html template(context)
    else if isResource
      locals.e = @__proxifyHelpers(locals.e)
      morph    = Metamorph template(locals.e)
      update   = => morph.html template(locals.e)
    else
      locals  = @__proxifyHelpers(locals)
      morph   = Metamorph template(locals)
      update  = => morph.html template(locals)

    # This is here to break stack tree and save from 
    # repeating DOM handling
    update = update.debounce(0)

    @__metamorphs ||= []

    if isCollection
      for resource in locals.data
        resource.bind 'changed', update
    if isResource || isCollection
      locals.bind 'changed', update
    else
      for key, object of locals
        if locals.hasOwnProperty key
          if object?.bind? && object?.unbind?
            object.bind 'changed', update
            @__metamorphs.push [object, update]

    morph.outerHTML()

  __removeMetamorphs: ->
    if @__metamorphs
      for [object, callback] in @__metamorphs
        object.unbind callback