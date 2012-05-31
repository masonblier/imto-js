# Interpreter

Context = require('./context')

class Interpreter
  constructor: () ->
    @context = new Context()

  execute: (code) ->
    @context.myvar = "1"

module.exports = Interpreter
