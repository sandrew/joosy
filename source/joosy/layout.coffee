#= require joosy/joosy
#= require joosy/widget
#= require joosy/modules/log
#= require joosy/modules/events
#= require joosy/modules/container
#= require joosy/modules/renderer
#= require joosy/modules/time_manager
#= require joosy/modules/widgets_manager
#= require joosy/modules/filters
#= require joosy/helpers/view

#
# Base class for all of your Joosy Layouts.
# @see http://guides.joosy.ws/guides/layouts-pages-and-routing.html
#
# @example Sample application layout
#   class @ApplicationLayout extends Joosy.Layout
#     @view 'application'
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
# @include Joosy.Modules.Container
# @include Joosy.Modules.Renderer
# @include Joosy.Modules.TimeManager
# @include Joosy.Modules.WidgetsManager
# @include Joosy.Modules.Filters
#
class Joosy.Layout extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.WidgetsManager
  @include Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad', 'afterLoad', 'afterUnload'

  @registerSequencedFilters \
    #
    # Sets the method which will controll the painting preparation proccess.
    #
    # This method will be called right ater previous page {Joosy.Page.erase} and in parallel with
    #   page data fetching so you can use it to initiate preloader.
    #
    # @note Given method will be called with `complete` function as parameter. As soon as your
    #   preparations are done you should call that function.
    #
    # @example Sample before painter
    #   @beforePaint (container, complete) ->
    #     if !@data # checks if parallel fetching finished
    #       $('preloader').slideDown -> complete()
    #
    #
    'beforePaint',

    #
    # Sets the method which will controll the painting proccess.
    #
    # This method will be called after fetching, erasing and beforePaint is complete.
    # It should be used to setup appearance effects of page.
    #
    # @note Given method will be called with `complete` function as parameter. As soon as your
    #   preparations are done you should call that function.
    #
    # @example Sample painter
    #   @paint (container, complete) ->
    #     @container.fadeIn -> complete()
    #
    'paint',

    #
    # Sets the method which will controll the erasing proccess.
    #
    # Use this method to setup hiding effect.
    #
    # @note Given method will be called with `complete` function as parameter. As soon as your
    #   preparations are done you should call that function.
    #
    # @note This method will be caled _before_ unload routines so in theory you can
    #   access page data from that. Think twice if you are doing it right though.
    #
    # @example Sample eraser
    #   @erase (container, complete) ->
    #     @container.fadeOut -> complete()
    #
    'erase',
    #
    # Sets the method which will controll the data fetching proccess.
    #
    # @note Given method will be called with `complete` function as parameter. As soon as your
    #   preparations are done you should call that function.
    #
    # @note You are strongly encouraged to NOT fetch anything with Layout!
    #   Use {Joosy.Page.fetch}
    #
    # @example Basic usage
    #   @fetch (complete) ->
    #     $.get '/rumbas', (@data) => complete()
    #
    'fetch'

  @helper 'page'

  #
  # Prefetched page data.
  #
  data: false
  dataFetched: false

  #
  # @param [Hash] params              List of route params
  #
  constructor: (@container, @params) ->
    @uid = Joosy.uid()

  #
  # @see Joosy.Router.navigate
  #
  navigate: ->
    Joosy.Router?.navigate arguments...

  #
  # This is required by {Joosy.Modules.Renderer}
  # Sets the base template dir to app_name/templates/layouts
  #
  __renderSection: ->
    'layouts'

  #
  # Layout bootstrap proccess.
  #
  #   * {Joosy.Modules.Container.__assignElements}
  #   * {Joosy.Modules.Container.__delegateEvents}
  #   * {Joosy.Modules.WidgetsManager.__setupWidgets}
  #
  __load: ->
    @__assignElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads()

  #
  # Layout destruction proccess.
  #
  #   * {Joosy.Modules.Container.__clearContainer}
  #   * {Joosy.Modules.TimeManager.__clearTime}
  #   * {Joosy.Modules.WidgetsManager.__unloadWidgets}
  #   * {Joosy.Modules.Renderer.__removeMetamorphs}
  #
  __unload: ->
    @__clearContainer()
    @__clearTime()
    @__unloadWidgets()
    @__removeMetamorphs()
    @__runAfterUnloads()

  #
  # Helpers that outputs container for the page
  #
  page: (tag, options={}) ->
    options.id = @uid
    Joosy.Helpers.Application.tag tag, options

  #
  # Gets layout element.
  #
  # @return [jQuery]
  #
  content: ->
    $("##{@uid}")

# AMD wrapper
if define?.amd?
  define 'joosy/layout', -> Joosy.Layout