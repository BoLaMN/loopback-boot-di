module.exports = ->

  @provider 'components', ->
    configs = {}

    @$get = (config) ->
      { definition } = config.one 'component-config'

      configs = config.from definition
      configs

  @run (components, events, loopback) ->

    Object.keys(components).forEach (key) ->
      component = components[key]
      component.fn loopback, component.definition

      events.emit 'components:' + key, component 

    return

