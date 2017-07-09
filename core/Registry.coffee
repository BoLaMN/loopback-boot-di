'use strict'

{ values } = require './Utils'

path = require 'path'
glob = require 'glob'

Plugin = require './Plugin'
PluginCollection = require './PluginCollection'

plugins = Symbol()
dir = path.join __dirname, '..'

class Registry

  constructor: (options) ->
    @[plugins] = {}

    @directories = []

    for key, value of options
      @[key] = value

    if @directories.indexOf(dir) is -1
      @directories.unshift dir

  list: ->
    Object.keys @[plugins]

  get: (name) ->
    @[plugins][name]

  set: (name, plugin) ->
    if not plugin instanceof Plugin
      json = JSON.stringify plugin
      throw new Error "#{json} is not a Plugin instance."

    @[plugins][name] = plugin

    plugin

  del: (name) ->
    delete @[plugins][name]

  glob: ->
    @files = @directories.reduce (results, directory) ->
      pattern = path.join directory, 'plugins', '**/index.{coffee,js}'
      files = glob.sync path.resolve pattern
      results.concat files
    , []
    @

  require: ->
    @files.forEach (filename) =>
      require(filename) @
    @

  resolve: ->
    Object.keys(@[plugins]).forEach (key) =>
      plugin = @[plugins][key]

      dependencies = plugin.dependencies or []

      dependencies.forEach (name) =>
        range = dependencies[name]
        dependency = @[plugins][name]

        if not dependency
          throw new Error "Dependency #{name} missing."

        dependency.dependents = dependency.dependents or {}
        dependency.dependents[plugin.name] = plugin

        plugin.metadata = plugin.metadata or {}
        plugin.metadata[name] = dependency

    @

  satisfy: (ordered, remaining) ->
    source = [].concat remaining
    target = [].concat ordered

    source.forEach (plugin, index) ->
      dependencies = values plugin.metadata

      isSatisfied = dependencies.every (dependency) ->
        target.indexOf(dependency) isnt -1

      if isSatisfied
        target.push plugin
        source.splice index, 1

    if source.length is 0 then target else @satisfy target, source

  prioritize: ->
    ordered = []
    remaining = [].concat values @[plugins]

    remaining.forEach (plugin, index) ->
      if not plugin.dependencies or plugin.dependencies.length is 0
        ordered.push plugin
        remaining.splice index, 1

    @prioritized = new PluginCollection @satisfy ordered, remaining

    @

  initialize: ->
    @prioritized.initialize()
    @
  assemble: ->
    @prioritized.assemble()
    @

  start: ->
    @prioritized.start()
    @

  core: ->

    @module 'Core', []

    .initializer ->

      @require
        inflector: './Inflector'
        utils: './Utils'

      @include './Is'
      @include './Env'

    @

  module: (name, dependencies) ->
    if dependencies
      @set name, new Plugin name, dependencies, @
    else
      @get name

  assembler: (name, factory) ->
    Object.defineProperty Plugin::, name, 
      value: factory

    @

module.exports = Registry
