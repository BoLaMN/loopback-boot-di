'use strict'

{ debug, dasheize } = require './Inflector'

dependencies = Symbol()
decorators = Symbol()
modules = Symbol()
plugins = Symbol()

class Injector

  constructor: ->
    @[dependencies] = {}
    @[decorators] = {}
    @[modules] = {}
    @[plugins] = {}

    @register 'injector',
      factory:
        $get: => @
      type: 'injector'

  register: (name, { type, factory, plugin }) ->
    if type is 'decorator'
      @[decorators][name] ?= []
      @[decorators][name].push factory
    else

      if @[dependencies][name]
        return

      @[dependencies][name] = factory.$get

      @[modules][type] ?= []
      @[modules][type].push name

    @[plugins][name] = plugin 

    if type is 'provider'
      @[dependencies][name + 'Provider'] = ->
        factory

    @

  has: (name) ->
    not not @[dependencies][name]

  get: (name, context) ->
    factory = @require name
    provider = @[dependencies][name + 'Provider']
    context ?= provider() if provider
    args = @inject @parse(factory), name
    service = @decorate name, factory.apply context, args 
    factory.apply context, args

  decorate: (name, service) ->
    (@[decorators][name] or []).forEach (decorate) ->
      service = decorate service
    service

  require: (name, owner) ->
    factory = @[dependencies][name]

    if not factory
      try
        module = require name
      catch e
      
      try 
        module = require dasheize name 
      catch e 
        
      if not module
        throw new ReferenceError "Dependency '#{name}' not defined"

      if module
        factory = @[dependencies][name] = -> module

    factory

  parse: (factory) ->
    s = factory + ''
    match = s.match /^function\s*[a-z0-9$_]*\s*\((.*)\)/i

    if not match
      return []

    match[1]
      .trim()
      .split /\s*,\s*/g
      .filter (item) ->
        item.length > 0

  inject: (deps, owner) ->
    deps.map (name) =>
      factory = @require name, owner
      args = @inject @parse(factory), owner
      service = @decorate name, factory args...
      if name is 'debug'
        dbg = owner or name or ''
        if @[plugins][dbg]
          plugin = debug(@[plugins][dbg]) + ':'
        service = service (plugin or '') + dasheize(dbg)
      service

  exec: (name, factory, context) ->
    provider = @[dependencies][name + 'Provider']
    context ?= provider() if provider
    args = @inject @parse(factory), name
    factory.apply context, args

  listByType: ->
    @[modules]

  list: ->
    Object.keys @[dependencies]

  inspect: ->
    @list()

module.exports = Injector
