"use strict"

injector = require './injectorInstance'

class Provider
  constructor: ->
    @settings = {}

  get: (prop, value) ->
    { get } = injector.get 'utils'

    get(@settings, prop) or value

  set: (prop, value) ->
    { set } = injector.get 'utils'

    set @settings, prop, value

  merge: ->
    merge = injector.get 'merge'
    
    merge @settings, arguments...

  extend: ->
    extend = injector.get 'extend'
    
    extend @settings, arguments...

module.exports = Provider