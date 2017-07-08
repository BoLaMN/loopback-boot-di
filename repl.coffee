fs = require 'fs'
path = require 'path'
repl = require 'repl'
vm = require 'vm'

coffee = require 'coffee-script'

{ updateSyntaxError } = require 'coffee-script/lib/coffee-script/helpers'

server = require('./core/Host').bootstrap()

injector = server.run()

runInContext = (js, context, filename) ->
  if context is global
    vm.runInThisContext js, filename
  else
    vm.runInContext js, context, filename

usage = ->
  list = injector.listByType()
  types = Object.keys list

  msg = "\n============================================\n" +
        " REPL Console\n\n" +
        " Primary handles available:\n\n"

  if types.length > 0
    types.forEach (type) ->
      modules = list[type].sort()
      name = type.charAt(0).toUpperCase() + type.slice(1)
      msg += " - #{ name }s: #{ modules.join(', ') }\n"

  msg += "============================================\n\n"

  msg

config =
  prompt: 'sh> ',
  historyFile: path.join process.env.HOME, '.repl_history' if process.env.HOME
  historyMaxInputSize: 10240
  eval: (input, context, filename, cb) ->
    input = input
      .replace /\uFF00/g, '\n'
      .replace /^\(([\s\S]*)\n\)$/m, '$1'
      .replace /^\s*try\s*{([\s\S]*)}\s*catch.*$/m, '$1'

    { Block, Assign, Value, Literal } = require 'coffee-script/lib/coffee-script/nodes'

    try
      tokens = coffee.tokens input

      referencedVars = (
        token[1] for token in tokens when token[0] is 'IDENTIFIER'
      )

      ast = coffee.nodes tokens

      ast = new Block [
        new Assign (new Value new Literal '_'), ast, '='
      ]

      js = ast.compile {bare: yes, locals: Object.keys(context), referencedVars}

      cb null, runInContext js, context, filename
    catch err
      updateSyntaxError err, input

      cb err

addMultilineHandler = ({rli, inputStream, outputStream, _prompt, prompt }) ->

  origPrompt = _prompt or prompt

  multiline =
    enabled: off
    initialPrompt: origPrompt.replace /^[^> ]*/, (x) -> x.replace /./g, '-'
    prompt: origPrompt.replace /^[^> ]*>?/, (x) -> x.replace /./g, '.'
    buffer: ''

  nodeLineListener = rli.listeners('line')[0]

  rli.removeListener 'line', nodeLineListener

  rli.on 'line', (cmd) ->
    if multiline.enabled
      multiline.buffer += "#{cmd}\n"

      rli.setPrompt multiline.prompt
      rli.prompt true
    else
      rli.setPrompt origPrompt

      nodeLineListener cmd

    return

  inputStream.on 'keypress', (char, key) ->
    return unless key and key.ctrl and not key.meta and not key.shift and key.name is 'v'

    if multiline.enabled
      unless multiline.buffer.match /\n/
        multiline.enabled = not multiline.enabled

        rli.setPrompt origPrompt
        rli.prompt true

        return

      return if rli.line? and not rli.line.match /^\s*$/

      multiline.enabled = not multiline.enabled

      rli.line = ''
      rli.cursor = 0
      rli.output.cursorTo 0
      rli.output.clearLine 1

      multiline.buffer = multiline.buffer.replace /\n/g, '\uFF00'
      rli.emit 'line', multiline.buffer
      multiline.buffer = ''
    else
      multiline.enabled = not multiline.enabled

      rli.setPrompt multiline.initialPrompt
      rli.prompt true

    return

addUsage = (shell) ->

  shell.commands.usage =
    help: 'Show usage commands'
    action: ->
      shell.outputStream.write usage injector.list()
      shell.displayPrompt()

addHistory = (shell, filename, maxSize) ->
  lastLine = null

  try
    stat = fs.statSync filename
    size = Math.min maxSize, stat.size

    readFd = fs.openSync filename, 'r'

    buffer = new Buffer(size)

    fs.readSync readFd, buffer, 0, size, stat.size - size
    fs.closeSync readFd

    shell.rli.history = buffer.toString().split('\n').reverse()
    shell.rli.history.pop() if stat.size > maxSize
    shell.rli.history.shift() if shell.rli.history[0] is ''
    shell.rli.historyIndex = -1

    lastLine = shell.rli.history[0]

  fd = fs.openSync filename, 'a'

  shell.rli.addListener 'line', (code) ->
    if code and code.length and code isnt '.history' and code isnt '.exit' and lastLine isnt code
      fs.writeSync fd, "#{code}\n"

      lastLine = code

  shell.on 'exit', ->
    fs.closeSync fd

  shell.commands[getCommandId(shell, 'history')] =
    help: 'Show command history'
    action: ->
      shell.outputStream.write "#{shell.rli.history[..].reverse().join '\n'}\n"
      shell.displayPrompt()

getCommandId = (shell, commandName) ->
  commandsHaveLeadingDot = shell.commands['.help']?

  if commandsHaveLeadingDot then ".#{commandName}" else commandName

start = ->
  coffee.register()

  shell = repl.start config

  context = shell.context
  context.server = server

  context.exit = ->
    process.exit 0

  process.nextTick ->
    modules = injector.list()

    modules.forEach (module) ->
      context[module] = injector.get module

    shell.outputStream.write usage modules
    shell.displayPrompt()

  shell.on 'exit', ->
    shell.outputStream.write '\n' if not shell.rli.closed

  addMultilineHandler shell
  addHistory shell, config.historyFile, config.historyMaxInputSize
  addUsage shell

  shell.commands[getCommandId(shell, 'load')].help = 'Load code from a file into this REPL session'

  shell

module.exports = start()