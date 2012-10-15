# Parser

Lexer = require './lexer'
Cursor = require './Cursor'

# wrapped in a function to give private instance scope
module.exports = class Parser extends Cursor
  constructor: (@lexer) ->
    super()
    @memo_index = -1
    @memos = []

  # at
  at: (req_index) =>
    # it follows the lexer sequentially, 
    # memoizing to provide back functionality
    while @memo_index < req_index
      unless @memos[@memo_index+=1]
        @memos[@memo_index] = @statement()
    @memos[req_index]

  statement: () =>
    subject = @lexer.next()
    subject = @lexer.next() while subject?.type is "linefeed"
    @expr(subject)

  expr: (subject) =>
    @block(subject) or 
    @function(subject) or
    @assignment(subject) or 
    subject

  block: (subject) =>
    if subject?.type is "block"
      return { 
        type: "block", source: subject.source,
        tracking: { start: subject.tracking.start, end: subject.tracking.end }
      }
    if subject?.type is "linefeed"
      if @lexer.peek()?.type is "block"
        n = @lexer.next()
        return {
          type: "block", source: n.source,
          tracking: { start: subject.tracking.start, end: n.tracking.end }
        }

  function: (subject) =>
    if subject?.type is "function"
      node = @expr(@lexer.next())
      return {
        type: "function", body: node,
        tracking: { start: subject.tracking.start, end: node.tracking.end }
      }

  assignment: (subject) =>
    @property_assignment(subject) or
    @local_assignment(subject)

  property_assignment: (subject) =>
    if subject?.type is "symbol"
      n = @lexer.peek()
      if n?.token is ":"
        node = @expr(@lexer.next(2))
        return {
          type: "property_assignment", symbol: subject.token, value: node,
          tracking: { start: subject.tracking.start, end: node.tracking.end }
        }
    return null

  local_assignment: (subject) =>
    if subject?.type is "symbol"
      n = @lexer.peek()
      if n?.token is "="
        node = @expr(@lexer.next(2))
        return {
          type: "assignment", symbol: subject.token, value: node,
          tracking: { start: subject.tracking.start, end: node.tracking.end }
        }
