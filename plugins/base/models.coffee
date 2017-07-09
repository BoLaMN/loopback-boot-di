module.exports = ->

  @provider 'models', (utils) ->
    { values } = utils 

    configs = {}

    resolve = (data) ->
      Object.keys(data).forEach (key) =>
        model = data[key]

        dependencies = values model.relations or []

        if model.base
          dependencies.push model.base 

        dependencies.forEach (dep) =>
          if not dep.model 
            return 

          dependency = data[dep.through or dep.model]

          if not dependency
            #console.error "Model #{dep.model} missing."
            return 

          #if dependency.type isnt 'belongsTo'
          dependency.dependents = dependency.dependents or {}
          dependency.dependents[model.name] = model

          model.metadata = model.metadata or {}
          model.metadata[dep.model] = dependency
      
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

    # model = registry.createModel config
    # config.fn model 
    # app.model model, config

    @$get = (config) ->
      info = config.one 'model-config'
      dirs = info._meta.sources

      configs = config.from info, dirs 

      Object.defineProperty configs, 'sort', 
        enumrable: false
        value: ->
          prioritize resolve configs 

      configs
