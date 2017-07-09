module.exports = (app) ->

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
