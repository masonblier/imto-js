# Parser

# requirements

Lexer = require './lexer'
Parser = require './parser'
Cursor = require './Cursor'

parse = (str) -> if str? then (new Parser(new Lexer(str))).all() else {}

clc = require('cli-color')
  # green: (a) -> a
  # blue:  (a) -> a
  # red:   (a) -> a


# sprint node function
sprint = (list, indent = "") ->
  (for node in list
    head = "#{indent}(#{clc.green(node.type)}"
    if node.type is "block"
      "#{head}\n#{sprint(parse(node.source),indent+"  ")}\n#{indent})"
    else if node.type is "function"
      "#{head}\n#{sprint([node.body],indent+"  ")}\n#{indent})"
    else if node.type is "execute"
      "#{head} #{clc.blue("#{node.symbol}")}#{if node.operator? then " #{node.operator} " else ""}#{if node.params?.length > 0 then "\n#{sprint(node.params,indent+"  ")}\n#{indent}" else ""})" 
    else if node.type is "assignment" or node.type is "property_assignment"
      "#{head} #{clc.blue("#{node.symbol}")}\n#{sprint([node.value],indent+"  ")}\n#{indent})" 
    else if node.type is "literal"
      "#{head} #{clc.red(node.token)})"
    else
      "#{head} '#{node.token}')"
  ).join "\n"

class ParseNode
  constructor: (options) ->
    for own p of options
      @[p] = options[p]
  toString: () =>
    sprint [@]

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
    if expr = @expr(subject)
      new ParseNode expr
    else
      undefined

  expr: (subject) =>
    expr =  @block(subject) or 
            @function(subject) or
            @assignment(subject) or 
            @operator(subject) or
            @execute(subject) or
            subject
    expr

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

  operator: (subject) =>
    if subject?.type is "operator"
      node = @expr(@lexer.next())
      value = if node then node else undefined
      return {
        type: "operator", operator: subject.token, value: value,
        tracking: { 
          start: subject.tracking.start, 
          end: (if node? then node else subject).tracking.end
        }
      }

  execute: (subject) =>
    if subject?.type is "symbol"
      params = []
      while @lexer.peek()? and @lexer.peek().token != "\n"
        expr = @expr(@lexer.next())
        if expr.type is "operator"
          return {
            type: "execute", symbol: subject.token, operator: expr.operator, 
            params: (if expr.value? then [expr.value] else undefined),
            tracking: { start: subject.tracking.start, end: expr.tracking.end }
          }
        else
          params.push expr
        break unless @lexer.peek()? and @lexer.peek().token == ","
        @lexer.next()
      return {
        type: 'execute'
        symbol: subject.token
        params: params
        tracking: { 
          start: subject.tracking.start, 
          end: (if params.length > 0 then params[params.length-1] else subject).tracking.end 
        }
      }

