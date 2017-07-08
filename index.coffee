'use strict'

server = require './core/Host'

if not module.parent
  server.bootstrap
    directories: [
      __dirname 
      process.cwd() 
    ]
  .run()
else

  ###
    require 'node-client'
      directories: [
        __dirname 
        process.cwd() 
      ]
    .run()

    or

    app = require 'node-client'

    options = directories: [
      __dirname 
      process.cwd() 
    ]

    app(options).run()
  ###

  module.exports = server.bootstrap