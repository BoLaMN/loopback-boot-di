'use strict'

module.exports = (app) ->

  app

  .module 'Base', [ ]

  .initializer ->

    @provider 'parsers', (path, env, fs) ->
        
      tokens = (entry) ->
        if entry.indexOf('${') > -1
          entry = entry.replace /\$\{([^}]+)\}/g, (token, name) =>
            env.get name, ''
        entry

      exts = [ ] 

      @add = (fn) ->
        (ext) ->
          require.extensions['.' + ext] = fn
          exts.push ext 

      @register = (exts, fn) ->
        return unless typeof fn is 'function'
        
        ext = @add (mod, file) ->
          content = fs.readFileSync file, 'utf-8'
          
          if content.charCodeAt(0) is 0xFEFF
            content = content.slice(1)

          fn mod, tokens(content), file
        
        if Array.isArray exts
          exts.forEach ext
        else ext exts

        @

      @$get = ->

        exts: exts 

        tokens: tokens

    @config (parsersProvider, csonParser, coffeeScript) ->

      parsersProvider

        .register 'js', (mod, content, file) ->
          mod._compile content, file 

        .register 'json', (mod, content) ->
          mod.exports = JSON.parse content

        .register 'coffee', (mod, content, file) ->
          js = coffeeScript.compile content, false, true
          mod._compile js, file 

        .register 'cson', (mod, content) -> 
          mod.exports = csonParser.parse content

      return 

    @provider 'config', (isEmpty, inflector, injector, merge, path, glob, env) ->
      { dasheize, underscore, camelize } = inflector

      directories = app.directories.map (directory) ->
        path.join directory, 'configs'

      addWithSuffixes = (list, base, suffixes...) ->
        add = (element) ->
          if list.indexOf(element) == -1
            list.push element

        not isEmpty(base) and add(base)

        add base + '.local'

        suffixes.forEach (suffix) =>
          if not isEmpty suffix
            base += (if base then '.' else '') + suffix

            add base

      build = (list) ->
        files = []

        parsers = injector.get 'parsers'

        node = env['NODE_ENV'] or 'dev'
        node_app = env['NODE_APP_INSTANCE']
        
        list.forEach (base) =>
          base = parsers.tokens(base) or base

          addWithSuffixes files, base, node_app
          addWithSuffixes files, base, node, node_app

        files

      get = (dirs, configs, fn) ->
        if typeof configs is 'function'
          return get directories, dirs, configs

        if not Array.isArray dirs 
          dirs = [ dirs ]

        parsers = injector.get 'parsers'
            
        names = configs.join ',' 
        exts = parsers.exts.join ','

        pattern = '{' + names + '}.{' + exts + '}'

        for dir in dirs
          ptrn = path.resolve path.join dir, pattern
          files = glob.sync ptrn

          for file in files
            fn file, require file 

        return

      one = (file, dirs = directories) ->
        name = path.basename file
        base = name.split('.')[0] 

        data = load [ file ], dirs

        data[base]

      load = (list, dirs = directories) ->
        if not Array.isArray dirs 
          dirs = [ dirs ]

        result = {}

        files = build list

        get dirs, files, (file, config) =>
          name = path.basename file
          base = name.split('.')[0] 

          result[base] = merge result[base] or {}, config

        result

      from = (list, dirs = directories) ->
        result = {}

        files = Object.keys list 

        files.forEach (file) ->
          orig = file.toLowerCase()

          dash = dasheize file 

          if dash isnt orig
            files.push dash

          under = underscore file 

          if under isnt orig
            files.push under

        get dirs, files, (file, config) =>
          ext = path.extname file
          name = path.basename file, ext
          base = camelize name.split('.')[0] 

          result[base] = list[base]

          if typeof config is 'function'
            result[base] ?= {}
            result[base].fn = config
          else 
            result[base] = merge result[base] or {}, config

        result
      
      @$get = -> 

        config = one 'config'
        config.get = get
        config.load = load
        config.one = one
        config.build = build 
        config.from = from 

        config

    @provider 'models', (utils) ->
      { values } = utils 

      configs = {}

      resolve = (data) ->
        Object.keys(data).forEach (key) =>
          model = data[key]

          dependencies = values model.relations or []

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
          if not model.relations or Object.keys(model.relations).length is 0
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

    @provider 'mixins', ->
      configs = {}
      
      # modelBuilder.mixins.define mixin.name, mixin.fn 

      @$get = (config) ->

        info = config.one 'model-config'
        dirs = info._meta.mixins 

        configs = config.from info, dirs    
        configs

    @provider 'components', ->
      configs = {}

      # component.fn app, component

      @$get = (config) ->

        info = config.one 'component-config'
        dirs = Object.keys info 

        configs = config.from info, dirs
        configs

    @provider 'middleware', ->
      
      # app.defineMiddlewarePhases phases 
      # app.middlewareFromConfig config.fn, config 

      @$get = (config) ->
        config.one 'middleware'

    @provider 'datasources', ->
      
      # app.dataSource key, obj  

      @$get = (config) ->
        config.one 'datasources'

    @provider 'boot', ->
      configs = []

      @$get = (config, path) ->

        dirs = app.directories.map (directory) ->
          path.join directory, 'boot'

        config.get dirs, [ '**' ], (file, config) =>
          if typeof config is 'function'
            configs.push config

        configs
