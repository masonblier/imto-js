# Command line interface
# this is largely based on 
# http://coffeescript.org/documentation/docs/repl.html

stdin = process.openStdin()
stdout = process.stdout

imto         = require './index'
readline     = require 'readline'
{inspect}    = require 'util'
{Script}     = require 'vm'
Module       = require 'module'

REPL_PROMPT = 'imto> '
REPL_PROMPT_MULTILINE = '----> '
REPL_PROMPT_CONTINUATION = '....> '
enableColours = no
unless process.platform is 'win32'
  enableColours = not process.env.NODE_DISABLE_COLORS

error = (err) ->
  stdout.write (err.stack or err.toString()) + '\n'
process.on 'uncaughtException', error

# The current backlog of multi-line code.
backlog = ''

# Our interpreter for the session
interpreter = new imto.Interpreter()

# The main REPL function. run is called every time 
# a line of code is entered. Attempt to evaluate the command. 
# If there's an exception, print it out instead of exiting.
run = (buffer) ->
  # remove single line comments
  buffer = buffer.replace /(^|[\r\n]+)(\s*)##?(?:[^#\r\n][^\r\n]*|)($|[\r\n])/, "$1$2$3"
  # trailing newlines
  buffer = buffer.replace /[\r\n]+$/, ""

  # if multilineMode
  #   backlog += "#{buffer}\n"
  #   repl.setPrompt REPL_PROMPT_CONTINUATION
  #   repl.prompt()
  #   return

  # if !buffer.toString().trim() and !backlog
  #   repl.prompt()
  #   return

  # evaluate
  try
    returnValue = switch mode
      when 1 then (interpreter.lex buffer).all()
      when 2 then (interpreter.parse buffer).all()
      else        interpreter.eval buffer
    repl.output.write "#{returnValue}\n"
  catch err
    error err

  repl.prompt()

# parse args
mode = 0

args = process.argv.splice(2)
if "-L" in args # lex only
  mode = 1 
if "-P" in args # lex and parse
  mode = 2

# handle piped input
if stdin.readable
  pipedInput = ''
  repl =
    prompt: -> stdout.write @_prompt
    setPrompt: (p) -> @_prompt = p
    input: stdin
    output: stdout
    on: ->
  stdin.on 'data', (chunk) ->
    pipedInput += chunk
    return unless /\n/.test pipedInput
    lines = pipedInput.split "\n"
    pipedInput = lines[lines.length - 1]
    for line in lines[...-1] when line
      # stdout.write "#{line}\n"
      run line
    return
  stdin.on 'end', ->
    for line in pipedInput.trim().split "\n" when line
      stdout.write "#{line}\n"
      run line
    stdout.write '\n'
    process.exit 0
# create repl from stdin
else
  if readline.createInterface.length < 3
    repl = readline.createInterface stdin
    stdin.on 'data', (buffer) -> repl.write buffer
  else
    repl = readline.createInterface stdin, stdout

multilineMode = off

repl.on 'attemptClose', ->
  if multilineMode
    multilineMode = off
    repl.output.cursorTo 0
    repl.output.clearLine 1
    repl._onLine repl.line
    return
  if backlog
    backlog = ''
    repl.output.write '\n'
    repl.setPrompt REPL_PROMPT
    repl.prompt()
  else
    repl.close()

repl.on 'close', ->
  repl.output.write '\n'
  repl.input.destroy()

repl.on 'line', run

repl.setPrompt REPL_PROMPT
repl.prompt()
