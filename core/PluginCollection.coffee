'use strict'

Collection = require './Collection'

class PluginCollection extends Collection
  constructor: ->
    return super

  start: ->
    @forEach (plugin) ->
      plugin.start()

  initialize: ->
    @forEach (plugin) ->
      plugin.initialize()

module.exports = PluginCollection