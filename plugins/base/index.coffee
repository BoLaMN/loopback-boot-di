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

    @provider 'config', (isEmpty, merge, path, glob, env) ->

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

      configs = @configs = {}

      @$get = (parsers, env, inflector) -> 
        { dasheize, underscore, camelize } = inflector

        node = env['NODE_ENV'] or 'dev'
        node_app = env['NODE_APP_INSTANCE']
        
        service = 
          configs: configs

          files: (list) ->
            files = []

            list.forEach (base) =>
              base = parsers.tokens(base) or base

              addWithSuffixes files, base, node_app
              addWithSuffixes files, base, node, node_app

            files

          glob: (dirs, configs, fn) ->
            if not Array.isArray dirs 
              dirs = [ dirs ]

            names = configs.join ',' 
            exts = parsers.exts.join ','

            pattern = '{' + names + '}.{' + exts + '}'

            for dir in dirs
              ptrn = path.resolve path.join dir, pattern
              files = glob.sync ptrn

              for file in files
                fn file, require file 

            return

          one: (dirs, file) ->
            name = path.basename file
            base = name.split('.')[0] 

            data = @load dirs, [ file ]

            data[base]

          load: (dirs, list) ->
            if not Array.isArray dirs 
              dirs = [ dirs ]

            files = @files list

            @glob dirs, files, (file, config) =>
              name = path.basename file
              base = name.split('.')[0] 

              @configs[base] = merge @configs[base] or {}, config

            @configs

          from: (conf, dirs, list) ->
            files = Object.keys list 

            files.forEach (file) ->
              orig = file.toLowerCase()

              dash = dasheize file 

              if dash isnt orig
                files.push dash

              under = underscore file 

              if under isnt orig
                files.push under

            @glob dirs, files, (file, config) =>
              ext = path.extname file
              name = path.basename file, ext
              base = camelize name.split('.')[0] 

              conf[base] = list[base]

              if typeof config is 'function'
                conf[base] ?= {}
                conf[base].fn = config
              else 
                conf[base] = merge conf[base] or {}, config

            conf

        service

    @provider 'models', ->
      configs = {}

      @$get = (config) ->

        configs: configs

        load: ->
          info = config.configs['model-config']
          dirs = info._meta.sources

          config.from configs, dirs, info
          
          configs

    @provider 'mixins', ->
      configs = {}

      @$get = (config) ->

        configs: configs

        load: ->
          info = config.configs['model-config']
          dirs = info._meta.mixins 

          config.from configs, dirs, info
          
          configs

    @run (config, env, models, mixins, path) ->
      directories = app.directories.map (directory) ->
        path.join directory, 'configs'

      conf = config.one directories, 'config'

      env.extend conf

      config.load directories, [
        'component-config'
        'datasources'
        'model-config'
        'middleware'
      ]

      models.load() 
      mixins.load() 


