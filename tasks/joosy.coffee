module.exports = (grunt) ->

  #
  # Joosy utilizes Grill to setup standalone environment
  # Check out https://github.com/inossidabile/grill
  #
  require('grill').setup grunt,
    prefix: 'joosy'
    assets:
      source: 'app'
      destination: 'public'
      vendor: ['vendor/*', 'node_modules/joosy/source']