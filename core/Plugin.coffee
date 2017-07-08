'use strict'

Controller = require './Controller'
Provider = require './Provider'

{ camelize } = require './Inflector'
{ zipObject } = require './Utils'

path = require 'path'
callsite = require "callsite"
injector = require './injectorInstance'

init = Symbol()
config = Symbol()
run = Symbol()

fn = (f) -> f()

class Plugin

  constructor: (@name, @dependencies) ->
    @injector = injector

    @[config] = [] 
    @[run] = []

  require: (modules) ->
    if typeof modules is 'string'
      modules = [ modules ]

    if Array.isArray modules
      modules = zipObject modules, modules, (v) ->
        camelize v, true

    Object.keys(modules).forEach (key) =>
      service = -> require modules[key]
      @factory key, service, 'require'
    @

  include: (filename) ->
    caller = callsite()[1]
    callerpath = caller.getFileName()
    filepath = path.join path.dirname(callerpath), filename
    require(filepath).bind(@)()
    @

  config: (configurator) ->
    @[config].push configurator 
    @

  run: (configurator) ->
    @[run].push configurator
    @

  @provider: (name, factory, type = 'provider') ->
    provider = new Provider

    injector.exec name, factory, provider

    injector.register name,
      factory: provider
      type: type
      plugin: @name 
      
    @

  provider: ->
    @constructor.provider arguments...
    @

  alias: (name, alias) ->
    @provider name, ->
      @$get = ->
        injector.get alias
    , 'alias'

    @

  constant: (name, factory) ->
    @factory name, factory, 'constant'

  value: (name, factory) ->
    @provider name, ->
      value = undefined

      @$get = ->
        if value
          return value
        value = injector.exec name, factory, @
        value
    , 'value'

  factory: (name, factory, type = 'factory') ->
    @provider name, ->
      instance = undefined

      @$get = ->
        if instance
          return instance
        instance = injector.exec name, factory
        instance
    , type

  controller: (name, factory) ->
    @factory name, ->
      instance = new Controller
      injector.exec name, factory, instance
      instance
    , 'controller'

  service: (name, factory) ->
    @provider name, ->
      @$get = factory
    , 'service'

  decorator: (name, factory) ->
    injector.register name,
      factory: factory
      type: 'decorator'
      plugin: @name 
    @

  start: ->
    @[config].forEach (configurator) =>
      injector.exec 'config', configurator, @

    @[run].forEach (configurator) =>
      injector.exec 'run', configurator, @

    @

  extension: (name, mutator) ->
    @factory name, mutator
    @

  assembler: (name, factory) ->
    @constructor::[name] = factory.bind(@)()
    @

  initializer: (callback) ->
    @[init] = callback
    @

  initialize: ->
    fn = @[init]?.bind @
    fn @ if fn
    @

module.exports = Plugin
