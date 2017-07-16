'use strict'

module.exports = (app) ->

  app

  .module 'Base', [ ]

  .initializer ->

    @include './boot'
    @include './datasources'
    @include './mixins'
    @include './components'
    @include './models'
    @include './config'
    @include './middleware'
    @include './parsers'
    @include './events'
    @include './connectors'

    @factory 'loopback', ->
      require('loopback')()

    @config (parsersProvider, csonParser, coffeeScript) ->

      parsersProvider

        .register 'js', (mod, content, file) ->
          mod._compile content, file 

        .register 'json', (mod, content) ->
          mod.exports = JSON.parse content

        .register 'coffee', (mod, content, file) ->
          js = coffeeScript.compile content, false, true
          mod._compile js, file 

        .register 'cson', (mod, content) -> 
          mod.exports = csonParser.parse content

      return 
