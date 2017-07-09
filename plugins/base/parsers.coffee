module.exports = ->

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
