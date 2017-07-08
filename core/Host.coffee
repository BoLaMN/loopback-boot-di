'use strict'

injector = require './injectorInstance'
Registry = require './Registry'

registry = Symbol()

callsite = require 'callsite'
path = require 'path'

class Host

  constructor: (options) ->
    @[registry] = new Registry options

  @bootstrap: (options = {}) ->
    caller = callsite()[1]
    callerpath = caller.getFileName()
    dir = path.dirname callerpath 

    options.directories ?= []
    options.directories.push dir 

    host = new Host options

    host[registry]
      .core()
      .glob()
      .require()
      .resolve()
      .prioritize()
      .initialize()

    host

  run: ->
    @injector = injector
    @[registry].start()
    @injector

  inspect: ->
    @[registry]

module.exports = Host
