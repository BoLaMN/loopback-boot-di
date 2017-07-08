camelize_rx = /(?:^|_|\-)(.)/g
titleize_rx = /(^|\s)([a-z])/g

humanize_rx1 = /_id$/
humanize_rx2 = /_|-|\./g
humanize_rx3 = /^\w/g

class Inflector
  @_plural: []
  @_singular: []
  @_uncountable: []
  @_human: []

  @plural: (regex, replacement) ->
    @_plural.unshift [regex, replacement]
    @

  @singular: (regex, replacement) ->
    @_singular.unshift [regex, replacement]
    @

  @human: (regex, replacement) ->
    @_human.unshift [regex, replacement]
    @

  @uncountable: (strings...) ->
    @_uncountable = @_uncountable.concat strings.map (x) ->
      new RegExp("#{x}$", 'i')
    @

  @irregular: (singular, plural) ->
    if singular.charAt(0) == plural.charAt(0)
      @plural new RegExp("(#{singular.charAt(0)})#{singular.slice(1)}$", "i"), "$1" + plural.slice(1)
      @plural new RegExp("(#{singular.charAt(0)})#{plural.slice(1)}$", "i"), "$1" + plural.slice(1)
      @singular new RegExp("(#{plural.charAt(0)})#{plural.slice(1)}$", "i"), "$1" + singular.slice(1)
    else
      @plural new RegExp("#{singular}$", 'i'), plural
      @plural new RegExp("#{plural}$", 'i'), plural
      @singular new RegExp("#{plural}$", 'i'), singular
    @

  @ordinalize: (number, radix=10) ->
    number = parseInt number, radix
    absNumber = Math.abs number

    if absNumber % 100 in [11..13]
      number + "th"
    else
      switch absNumber % 10
        when 1
          number + "st"
        when 2
          number + "nd"
        when 3
          number + "rd"
        else
          number + "th"

  @pluralize: (count, singular, plural, includeCount = true) ->

    pluralize = (word) ->
      for uncountableRegex in Inflector._uncountable
        return word if uncountableRegex.test word

      for [regex, replace_string] in Inflector._plural
        return word.replace regex, replace_string if regex.test word

      word

    if arguments.length < 2
      return pluralize count
    else
      result = if +count is 1
          singular
        else
          plural or pluralize singular

      if includeCount
        result = "#{count or 0} #{result}"

      result

  @singularize: (word) ->
    for uncountableRegex in Inflector._uncountable
      return word if uncountableRegex.test word

    for [regex, replace_string] in Inflector._singular
      return word.replace regex, replace_string if regex.test word

    word

  @camelize: (string, firstLetterLower, pluralize = false) ->
    string = string.replace camelize_rx, (str, p1) ->
      p1.toUpperCase()

    Inflector.pluralize string if pluralize

    if firstLetterLower
      string.substr(0,1).toLowerCase() + string.substr(1)
    else string

  @underscore: (string, c = '_') ->
    string
      .replace /([A-Z]+)([A-Z][a-z])/g, '$1' + c + '$2' 
      .replace /([a-z\d])([A-Z])/g, '$1' + c + '$2' 
      .replace '-', c
      .toLowerCase()

  @debug: (string) ->
    Inflector.underscore(string, ':')

  @dasheize: (string) ->
    Inflector.underscore string, '-'

  @titleize: (string) ->
    string.replace titleize_rx, (m, p1, p2) ->
      p1 + p2.toUpperCase()

  @capitalize: (string) ->
    string.charAt(0).toUpperCase() + string.slice(1).toLowerCase()

  @trim: (string) ->
    if string then string.trim() else ""

  @interpolate: (stringOrObject, keys) ->
    if typeof stringOrObject is 'object'
      string = stringOrObject[keys.count]

      unless string
        string = stringOrObject.other
    else
      string = stringOrObject

    for key, value of keys
      string = string.replace(new RegExp("%\\{#{key}\\}", "g"), value)

    string

  @humanize: (string) ->
    string = @underscore(string)

    for [regex, replace_string] in Inflector._human
      return string.replace regex, replace_string if regex.test string

    return string

    string
      .replace(humanize_rx1, '')
      .replace(humanize_rx2, ' ')
      .replace(humanize_rx3, (match) ->
        match.toUpperCase())

  @toSentence: (array) ->
    if array.length < 3
      array.join ' and '
    else
      array = array.slice()
      last = array.pop()

      itemString = array.join(', ')
      itemString += ", and #{last}"

      itemString

  @coerceInteger: (value, shouldThrow=false) ->
    if (typeof value is "string") and (value.match(/[^0-9]/) is null) and ("#{coercedValue = parseInt(value, 10)}" is value)
      coercedValue
    else if shouldThrow
      throw "#{value} was passed to coerceInteger but couldn't be coerced!"
    else
      value

module.exports = Inflector
  .plural /$/, 's'
  .plural /s$/i, 's'
  .plural /(ax|test)is$/i, '$1es'
  .plural /(octop|vir)us$/i, '$1i'
  .plural /(octop|vir)i$/i, '$1i'
  .plural /(alias|status)$/i, '$1es'
  .plural /(bu)s$/i, '$1ses'
  .plural /(buffal|tomat)o$/i, '$1oes'
  .plural /([ti])um$/i, '$1a'
  .plural /([ti])a$/i, '$1a'
  .plural /sis$/i, 'ses'
  .plural /(?:([^f])fe|([lr])f)$/i, '$1$2ves'
  .plural /(hive)$/i, '$1s'
  .plural /([^aeiouy]|qu)y$/i, '$1ies'
  .plural /(x|ch|ss|sh)$/i, '$1es'
  .plural /(matr|vert|ind)(?:ix|ex)$/i, '$1ices'
  .plural /([m|l])ouse$/i, '$1ice'
  .plural /([m|l])ice$/i, '$1ice'
  .plural /^(ox)$/i, '$1en'
  .plural /^(oxen)$/i, '$1'
  .plural /(quiz)$/i, '$1zes'

  .singular /s$/i, ''
  .singular /(n)ews$/i, '$1ews'
  .singular /([ti])a$/i, '$1um'
  .singular /((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i, '$1$2sis'
  .singular /(^analy)ses$/i, '$1sis'
  .singular /([^f])ves$/i, '$1fe'
  .singular /(hive)s$/i, '$1'
  .singular /(tive)s$/i, '$1'
  .singular /([lr])ves$/i, '$1f'
  .singular /([^aeiouy]|qu)ies$/i, '$1y'
  .singular /(s)eries$/i, '$1eries'
  .singular /(m)ovies$/i, '$1ovie'
  .singular /(x|ch|ss|sh)es$/i, '$1'
  .singular /([m|l])ice$/i, '$1ouse'
  .singular /(bus)es$/i, '$1'
  .singular /(o)es$/i, '$1'
  .singular /(shoe)s$/i, '$1'
  .singular /(cris|ax|test)es$/i, '$1is'
  .singular /(octop|vir)i$/i, '$1us'
  .singular /(alias|status)es$/i, '$1'
  .singular /^(ox)en/i, '$1'
  .singular /(vert|ind)ices$/i, '$1ex'
  .singular /(matr)ices$/i, '$1ix'
  .singular /(quiz)zes$/i, '$1'
  .singular /(database)s$/i, '$1'

  .irregular 'person', 'people'
  .irregular 'man', 'men'
  .irregular 'child', 'children'
  .irregular 'sex', 'sexes'
  .irregular 'move', 'moves'
  .irregular 'cow', 'kine'
  .irregular 'zombie', 'zombies'

  .uncountable 'equipment', 'information', 'rice', 'money', 'species', 'series', 'fish', 'sheep', 'jeans'
