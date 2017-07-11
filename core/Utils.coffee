
class Utils

  @values: (object = {}) ->
    Object.keys(object).map (key) ->
      object[key]

  @zipObject: (a1, a2, fn = ->) ->
    obj = {}
    for key, idx in a1
      obj[fn(key)] = a2[idx]
    obj

  @extend: (target, args...) ->
    args.forEach (source) ->
      return unless source

      for own key of source
        if source[key] isnt undefined
          target[key] = source[key]

    target

  @defer: (cb) ->
    resolve = undefined
    reject = undefined

    promise = new Promise (args...) ->
      [ resolve, reject ] = args

    if cb
      promise.asCallback cb

    resolve: resolve
    reject: reject
    promise: promise

  @clone: (obj) ->

    switch Object::toString.call(obj)
      when '[object Array]'
        copy = new Array(obj.length)

        i = 0
        l = obj.length

        while i < l
          copy[i] = Utils.clone(obj[i])
          i++

        return copy
      when '[object Object]'
        copy = {}

        for key of obj
          if Object::hasOwnProperty.call(obj, key)
            copy[key] = Utils.clone(obj[key])

        return copy
      when '[object RegExp]'
        flags = ''
        flags += if obj.multiline then 'm' else ''
        flags += if obj.global then 'g' else ''
        flags += if obj.ignoreCase then 'i' else ''

        return new RegExp(obj.source, flags)
      when '[object Date]'
        return new Date(obj.getTime())
      else
        return obj

    return

  @getArgs: (fn) ->
    fn
      .toString()
      .match(/function\s.*?\(([^)]*)\)/)[1]
    .split ','
    .map (arg) -> arg.replace(/\/\*.*\*\//, '').trim()
    .filter (arg) -> arg

  @each: (fns, iterate, callback) ->
    count = 0

    run = (item, index) ->
      iterate item, (err, obj) ->
        if err
          callback err
          callback = ->
          return

        count += 1

        if count is fns.length
          callback()

    if not fns.length
      return callback()

    fns.forEach run

  @get: (obj, path = '') ->
    attrs = path.split '.'
    attrs.reduce((acc, attr) ->
      acc[attr] if acc?[attr]?
    , obj) or undefined

  @set: (obj, path = '', value) ->
    attrs = path.split '.'
    key = chain.shift()

    attrs.reduce((acc, attr) ->
      acc[attr] ?= {}
      acc[attr] 
    , obj)[key] = value

  @flatten: (arr, ret = []) ->
    if arr and not Array.isArray arr
      return [ arr ]

    for ar in arr 
      if Array.isArray ar
        Utils.flatten ar, ret
      else
        ret.push ar

    ret

module.exports = Utils