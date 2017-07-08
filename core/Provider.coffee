"use strict"

{ get, set } = require './Utils'

class Provider
  constructor: ->
    @settings = {}

  get: (prop, value) ->
    get(@settings, prop) or value

  set: (prop, value) ->
    set @settings, prop, value

module.exports = Provider