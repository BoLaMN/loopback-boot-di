module.exports = ->

  @provider 'datasources', ->
    
    # app.dataSource key, obj  

    @$get = (config) ->
      config.one 'datasources'
