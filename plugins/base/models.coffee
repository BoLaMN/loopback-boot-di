module.exports = ->

  @provider 'models', (utils) ->
    { values } = utils 

    resolve = (data) ->
      Object.keys(data).forEach (key) =>
        model = data[key]

        dependencies = values model.relations or []

        if model.base
          dependencies.push model: model.base 

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
        dependencies = values model.relations

        if model.base
          dependencies.push model.base 

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
        if not model.base and (not model.relations or Object.keys(model.relations).length is 0)
          ordered.push model
          remaining.splice index, 1

      satisfy data, ordered, remaining

    @$get = (config) ->
      { definition } = config.one 'model-config'

      dirs = definition._meta.sources

      prioritize resolve config.from definition, dirs 

  @run (models, loopback, debug, events, utils) ->
    registry = loopback.registry or loopback.loopback
    
    models.forEach (data) ->
      name = data.name

      if not data.definition
        model = registry.getModel name

        if not model
          throw new Error 'Cannot configure unknown model %s', name 
        
        debug 'Configuring existing model %s', name
      else
        debug 'Creating new model %s %j', name, data.definition

        { mixins } = data.definition
        
        delete data.definition.mixins

        mixinNames = Object.keys(mixins or {})

        events.get 'mixins', mixinNames, (mixes) ->
          model = registry.createModel data.definition 

          if data.fn
            debug 'Loading customization script %s'

            data.fn model

          events.get 'datasources', data.dataSource, (datasource) ->
            loopback.model model, data.config
