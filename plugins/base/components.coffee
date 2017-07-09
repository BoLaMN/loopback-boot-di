module.exports = ->

  @provider 'components', ->
    configs = {}

    # component.fn app, component

    @$get = (config) ->

      info = config.one 'component-config'
      dirs = Object.keys info 

      configs = config.from info, dirs
      configs
