toFunction = require './ToFunction'
toString = Object::toString

module.exports = ->

  @factory 'filter', ->
    (array, predicate) ->
      fn = toFunction predicate
      array.filter fn

  @factory 'remove', ->
    (array = [], value) ->
      if not Array.isArray array
        return -1

      index = array.indexOf value

      if index >= 0
        array.splice index, 1

      index

  @assembler 'is', ->
    (name, factory) ->
      @factory 'is' + name, factory, 'helper'

  @is 'Arguments', ->
    (value) -> typeof value is 'object' and
               value isnt null and
               toString.call(value) is '[object Arguments]'

  @is 'Null', ->
    (value) -> value is null

  @is 'Number', (isObjectLike) ->
    (value) -> typeof value is 'number' or
               isObjectLike(value) and toString.call(value) is '[object Number]'

  @is 'Boolean', (isObjectLike) ->
    (value) -> value is true or
               value is false or
               isObjectLike(value) and toString.call(value) is '[object Boolean]'

  @is 'Prototype', ->
    (value) ->
      Ctor = value?.constructor
      value is typeof Ctor is 'function' and Ctor.prototype or Object.prototype

  @is 'ArrayLike', (isLength) ->
    (value) ->
      value isnt null and
      typeof value isnt 'function' and
      isLength value.length

  @is 'ArrayLikeObject', (isObjectLike, isArrayLike) ->
    (value) ->
      isObjectLike(value) and isArrayLike(value)

  @is 'Length', ->
    (value) ->
      typeof value is 'number' and
      value > -1 and
      value % 1 is 0 and
      value <= 9007199254740991

  @is 'Empty', (isArrayLike, isArguments, isPrototype) ->
    (value) ->
      if not value?
        return true

       hasValue = isArrayLike(value) and
                  Array.isArray(value) or
                  typeof value is 'string' or
                  typeof value.splice is 'function' or
                  isArguments value

       if hasValue
        return not value.length

      if isPrototype(value)
        return not Object.keys(value).length

      for own key of value
        return false

      true

  @is 'Undefined', ->
    (value) -> value is undefined

  @is 'Defined', ->
    (value) -> value isnt undefined

  @is 'Object', ->
    (value) ->
      type = typeof value

      value isnt null and (type is 'object' or type is 'function')

  @is 'ObjectLike', ->
    (value) -> typeof value is 'object' and value isnt null

  @is 'Date', (isObjectLike) ->
    (value) -> isObjectLike(value) and toString.call(value) is '[object Date]'

  @is 'RegExp', (isObjectLike) ->
    (value) -> isObjectLike(value) and toString.call(value) is '[object RegExp]'

  @is 'String',  ->
    (value) ->
      type = typeof value

      type is 'string' or
      type is 'object' and
      value isnt null and
      not Array.isArray(value) and
      toString.call(value) is '[object String]'

  @is 'Function', (isObject) ->
    (value) ->
      if not isObject value
        return false

      tag = toString.call value

      tag is '[object Function]' or
      tag is '[object AsyncFunction]' or
      tag is '[object GeneratorFunction]' or
      tag is '[object Proxy]'

  @is 'Value', ->
    (value) ->
      if typeof value is 'number'
        return not isNaN value
      value isnt null

  @is 'PlainObject', (isObjectLike) ->
    (value) ->
      if not isObjectLike(value) or toString.call(value) isnt '[object Object]'
        return false

      proto = Object.getPrototypeOf value
      objectCtorString = toString.call Object

      if proto is null
        return true

      Ctor = Object::hasOwnProperty.call(proto, 'constructor') and proto.constructor

      typeof Ctor is 'function' and Ctor instanceof Ctor and toString.call(Ctor) is objectCtorString

  @factory 'extend', (isObjectLike, isPlainObject, isFunction, isRegExp, isDate) ->
    extend = (dst, objs..., deep = false) ->
      for obj in objs

        if not isObjectLike(obj) and not isFunction obj
          continue

        for own key, src of obj
          if deep and isObjectLike src
            if isDate src
              dst[key] = new Date src.valueOf() 
            else if isRegExp(src)
              dst[key] = new RegExp src
            else
              if not isObjectLike dst[key] 
                dst[key] = if Array.isArray(src) then [] else {}

              if isPlainObject src
                extend dst[key], src, true
              else 
                dst[key] = src
          else
            dst[key] = src

      dst

    extend

  @factory 'merge', (extend) ->
    (dst, objs...) ->
      extend dst, objs..., true
