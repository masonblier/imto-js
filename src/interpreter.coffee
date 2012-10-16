# Interpreter

Context = require('./context')
Lexer = require('./lexer')
Parser = require('./parser')

class Interpreter
  constructor: () ->
    @context = new Context()

  lex: (code) ->
    # make lexer
    (new Lexer(code))

  parse: (code) ->
    (new Parser(new Lexer(code)))

  eval: (code) ->
    @context.myvar = "1"

module.exports = Interpreter
