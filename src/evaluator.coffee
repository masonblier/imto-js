# Evaluator

{ImtoError} = require './utils'

class RuntimeError extends ImtoError

module.exports = class Evaluator
  # constructor
  constructor: (@context) ->

  # run all in context
  run: (parser) =>
    last = undefined
    while parser.peek()?
      parser.next() if parser.peek().type is "comment"
      last = @exec(parser.next())
    return last

  # execute
  exec: (node) =>
    return @assignment(node) or
           @hash_assignment(node) or
           @execute(node) or
           @function(node) or
           @block(node) or
           @operator(node) or
           @number(node)

  # assignment
  assignment: (node) =>
    if node.type is "assignment"
      @context.private.set node.symbol, @exec node.value

  # property assignment
  hash_assignment: (node) =>
    if node.type is "hash_assignment"
      @context.public.set node.symbol, @exec node.value
      @context.toJSON()

  # execute
  execute: (node) =>
    if node.type is "execute"
      # todo factor this into resolve()
      res = @context.public.get node.symbol
      unless res
        res = @context.private.get node.symbol
      unless res
        throw new RuntimeError("Undefined variable: #{node.symbol}", tracking: node.tracking.start)
      if res.type is "function"
        res = @exec res.body
      res

  # function
  function: (node) =>
    if node.type is "function"
      return node

  # block
  block: (node) =>
    if node.type is "block"
      return @run node.parse()

  # operator
  operator: (node) =>
    if node.type is "operator"
      if node.operator is "+"
        return @exec(node.left) + @exec(node.right)
      if node.operator is "-"
        return @exec(node.left) - @exec(node.right)

  # number
  number: (node) =>
    if node.type is "number"
      return node.value
