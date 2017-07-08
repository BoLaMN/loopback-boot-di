
globals = /\b(Array|Date|Object|Math|JSON)\b/g

map = (str, props, fn) ->
  re = /\.\w+|\w+ *\(|"[^"]*"|'[^']*'|\/([^/]+)\/|[a-zA-Z_]\w*/g
  str.replace re, (_) ->
    if '(' == _[_.length - 1]
      return fn(_)
    if ! ~props.indexOf(_)
      return _
    fn _

unique = (arr) ->
  ret = []
  i = 0

  while i < arr.length
    if ~ret.indexOf(arr[i])
      i++
      continue

    ret.push arr[i]
    i++

  ret

prefixed = (str) ->
  (_) ->
    str + _

expr = (str, fn) ->
  p = unique str
    .replace(/\.\w+|\w+ *\(|"[^"]*"|'[^']*'|\/([^/]+)\//g, '')
    .replace(globals, '')
    .match(/[a-zA-Z_]\w*/g) or []

  if fn and 'string' == typeof fn
    fn = prefixed(fn)

  if fn
    return map(str, p, fn)

  p

toFunction = (obj) ->
  switch {}.toString.call(obj)
    when '[object Object]'
      return objectToFunction(obj)
    when '[object Function]'
      return obj
    when '[object String]'
      return stringToFunction(obj)
    when '[object RegExp]'
      return regexpToFunction(obj)
    else
      return defaultToFunction(obj)

  return

defaultToFunction = (val) ->
  (obj) ->
    val == obj

regexpToFunction = (re) ->
  (obj) ->
    re.test obj

stringToFunction = (str) ->
  if /^ *\W+/.test(str)
    return new Function('_', 'return _ ' + str)

  new Function('_', 'return ' + get(str))

objectToFunction = (obj) ->
  match = {}

  for key of obj
    match[key] = if typeof obj[key] == 'string' then defaultToFunction(obj[key]) else toFunction(obj[key])

  (val) ->
    if typeof val != 'object'
      return false

    for key of match
      if !(key of val)
        return false

      if !match[key](val[key])
        return false

    true

get = (str) ->
  props = expr(str)

  if !props.length
    return '_.' + str

  i = 0

  while i < props.length
    prop = props[i]

    val = '_.' + prop
    val = '(\'function\' == typeof ' + val + ' ? ' + val + '() : ' + val + ')'

    str = stripNested(prop, str, val)
    i++

  str

stripNested = (prop, str, val) ->
  str.replace new RegExp('(\\.)?' + prop, 'g'), ($0, $1) ->
    if $1 then $0 else val

module.exports = toFunction
