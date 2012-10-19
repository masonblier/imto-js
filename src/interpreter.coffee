# Interpreter

Lexer = require('./lexer')
Parser = require('./parser')
Context = require('./context')
Evaluator = require('./evaluator')

class Interpreter
  constructor: () ->
    @context = new Context()

  lex: (code) ->
    (new Lexer(code))

  parse: (code) ->
    (new Parser(new Lexer(code)))

  eval: (code) ->
    cursor = @parse code
    (new Evaluator @context).run(cursor)

module.exports = Interpreter
