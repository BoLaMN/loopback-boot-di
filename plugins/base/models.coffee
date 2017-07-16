module.exports = ->

  @provider 'models', ->
    configs = {} 

    @$get = (config) ->
      { definition } = config.one 'model-config'

      dirs = definition._meta.sources
      
      configs = config.from definition, dirs    
      configs

  @run (models, loopback, debug, events, utils) ->
    registry = loopback.registry or loopback.loopback

    { values } = utils 

    resolve = (data) ->
      Object.keys(data).forEach (key) =>
        model = data[key]

        dependencies = values model.definition.relations or []

        if model.definition.base
          dependencies.push model: model.definition.base 

        dependencies.forEach (dep) =>
          if not dep.model 
            return 

          dependency = data[dep.through or dep.model]

          if not dependency
            return 

          if not dependency.dependents
            Object.defineProperty dependency, 'dependents', 
              enumrable: false
              value: {}

          dependency.dependents[model.name] = model

          if not model.dependencies
            Object.defineProperty model, 'dependencies', 
              enumrable: false
              value: {}

          model.dependencies[dep.model] = dependency
      
      data

    satisfy = (data, ordered, remaining) ->
      source = [].concat remaining
      target = [].concat ordered

      source.forEach (model, index) ->
        dependencies = values model.definition.relations

        if model.definition.base
          dependencies.push model.definition.base 

        isSatisfied = dependencies.filter (dependency) ->
          not (dependency.type is 'belongsTo' or 
            not dependency.model or 
            dependency.model is model.name or 
            not data[dependency.through or dependency.model] or 
            target.indexOf(data[dependency.through or dependency.model]) isnt -1)

        if not isSatisfied.length 
          target.push model
          source.splice index, 1

      if source.length is 0 then target else satisfy data, target, source

    prioritize = (data) ->
      ordered = []
      remaining = [].concat values data

      remaining.forEach (model, index) ->
        if not model.definition.base and (not model.definition.relations or Object.keys(model.definition.relations).length is 0)
          ordered.push model
          remaining.splice index, 1

      satisfy data, ordered, remaining

    prioritize(resolve(models)).forEach ({ name, fn, definition, config }) ->
      if not definition
        model = registry.getModel name

        if not model
          throw new Error 'Cannot configure unknown model %s', name 
        
        debug 'Configuring existing model %s', name
      else
        debug 'Creating new model %s %j', name, definition

        events.get 'datasources', config.dataSource, (datasource) ->
          names = Object.keys definition.mixins or {} 
          
          events.get 'mixins', names, (mixins) ->

            model = registry.createModel definition 

            if fn
              debug 'Loading customization script %s'

              fn model

            loopback.model model, config
