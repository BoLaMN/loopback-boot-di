path = require 'path'

config =

  MONGO_USER: null
  MONGO_PASS: null
  MONGO_HOST: null
  MONGO_PORT: null
  MONGO_DBNAME: "mongo"

  SES_USER: null
  SES_PASS: null
  SES_HOST: null
  SES_PORT: null

  REDIS_HOST: null

  AUTH_HOST: null

  cloudfront:
    keypairId: '1234'
    privateKeyPath: path.resolve path.join(__dirname, '/fixtures/cloudfront.pem')

module.exports = config