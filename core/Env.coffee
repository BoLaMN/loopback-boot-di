"use strict"

module.exports = ->

  @provider 'env', ->
    settings = @settings = {}

    mode = (process.env.NODE_ENV or 'development').toLowerCase()

    for own key, value of process.env
      value = true if value is 'true'
      value = false if value is 'false'

      @settings[key] = value

    equals = (anotherMode) ->
      mode is anotherMode

    @mode = (newMode) ->
      if newMode
        mode = newMode
      else
        mode

    @is = equals

    @load = (definition) ->
      @settings = definition

    @$get = (utils, merge) ->

      settings.get = (path, value) ->
        utils.get(settings, path) or value

      settings.has = (path) ->
        not not utils.get settings, path

      settings.extend = (values) ->
        merge settings, values 
         
      settings.is = equals

      settings

  @factory 'debug', (env, inspect) ->
    debug = require 'debug'

    (name) -> 
      if not env.DEBUG 
        return -> 

      debug name

  @factory 'inspect', (env) ->
    { inspect } = require 'util'

    (args...) -> 
      if not env.DEBUG 
        return args

      inspect args... 
