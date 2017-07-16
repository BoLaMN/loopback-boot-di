path = require 'path'

{ CLIENT_ID, CLIENT_SECRET, CLIENT_KEY } = process.env

module.exports =

  id: CLIENT_ID
  secret: CLIENT_SECRET
  key: CLIENT_KEY
