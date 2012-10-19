# Parser

# requirements

Lexer = require './lexer'
Parser = require './parser'
Cursor = require './Cursor'

class ParseError extends Error

parse = (str) -> if str? then (new Parser(new Lexer(str))).all() else {}

precedence = {"+":1,".":2}

clc = require('cli-color')
  # green: (a) -> a
  # blue:  (a) -> a
  # red:   (a) -> a


# sprint node function
sprint = (list, indent = "") ->
  (for node in list
    pp list unless node
    head = "#{indent}(#{clc.green(node.type)}"
    if node.type is "block"
      "#{head}\n#{sprint(parse(node.source),indent+"  ")}\n#{indent})"
    else if node.type is "function"
      "#{head}\n#{sprint([node.body],indent+"  ")}\n#{indent})"
    else if node.type is "execute"
      "#{head} #{clc.blue("#{node.symbol}")}#{if node.params?.length > 0 then "\n#{sprint(node.params,indent+"  ")}\n#{indent}" else ""})" 
    else if node.type is "hash"
      "#{head} #{if node.statements?.length > 0 then "\n#{sprint(node.statements,indent+"  ")}\n#{indent}" else ""})" 
    else if node.type is "operator"
      "#{head} #{clc.blue("#{node.operator}")}\n#{sprint([node.left, node.right],indent+"  ")}\n#{indent})" 
    else if node.type is "assignment" or node.type is "hash_assignment"
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

module.exports = class Parser extends Cursor
  constructor: (@lexer) ->
    super()
    @memo_index = -1
    @memos = []

  # at
  at: (req_index) =>
    # there's no real random access here. 
    # it follows the lexer sequentially, 
    # memoizing to provide the illution of random access
    while @memo_index < req_index
      unless @memos[@memo_index+=1]
        @memos[@memo_index] = @statement()
    @memos[req_index]

  statement: () =>
    @lexer.next() while @lexer.peek()?.type is "linefeed"
    if expr = @expr()
      new ParseNode expr
    else
      undefined

  expr: () =>
    expr = @tidbit() 
    expr = @operator(expr) or expr
    expr

  operator: (expr) =>
    if expr? and @lexer.peek()? and @lexer.peek().type == "operator"
      operator = @lexer.next()
      node = @tidbit()
      if expr? and @lexer.peek()? and @lexer.peek().type == "operator"
        if precedence[@lexer.peek().token]? and precedence[@lexer.peek().token] > precedence[operator.token]
          node = @operator(node)
        result = { 
          type: 'operator', left: expr, right: node, operator: operator.token,
          tracking: { 
            start: expr.tracking.start, 
            end: (if node? then node else operator).tracking.end
          }
        }
        return @operator(result) or result
      return { 
        type: 'operator', left: expr, right: node, operator: operator.token,
        tracking: { 
          start: expr.tracking.start, 
          end: (if node? then node else operator).tracking.end
        }
      }

  tidbit: () =>
    expr = @block() or 
           @function() or
           @assignment() or
           @execute() or
    expr = @lexer.next() unless expr
    expr

  block: () =>
    if @lexer.peek()?.type is "block"
      subject = @lexer.next()
      return { 
        type: "block", source: subject.source,
        tracking: { start: subject.tracking.start, end: subject.tracking.end }
      }
    if @lexer.peek()?.type is "linefeed"
      if @lexer.peek(2)?.type is "block"
        subject = @lexer.next(2)
        n = @lexer.next()
        return {
          type: "block", source: n.source,
          tracking: { start: subject.tracking.start, end: n.tracking.end }
        }

  function: () =>
    if @lexer.peek()?.type is "function"
      subject = @lexer.next()
      node = @expr()
      return {
        type: "function", body: node, signature: subject.source,
        tracking: { start: subject.tracking.start, end: node.tracking.end }
      }

  assignment: () =>
    @hash_assignment() or
    @local_assignment()

  hash_assignment: () =>
    if @lexer.peek()?.type is "symbol"
      n = @lexer.peek(2)
      if n?.token is ":"
        subject = @lexer.next()
        @lexer.next()
        node = @expr()
        first = {
          type: "hash_assignment", symbol: subject.token, value: node,
          tracking: { start: subject.tracking.start, end: node.tracking.end }
        }
        if @lexer.peek()?.token == ','
          statements = [first]
          while @lexer.peek()?.token == ','
            @lexer.next()
            node = @hash_assignment()
            throw new ParseError("unfinished hash") unless node?
            statements.push node
          return {
            type: "hash", statements: statements,
            tracking: { start: subject.tracking.start, end: node.tracking.end }
          }
        else
          return first
    return null

  local_assignment: () =>
    if @lexer.peek()?.type is "symbol"
      n = @lexer.peek(2)
      if n?.token is "="
        subject = @lexer.next()
        @lexer.next()
        node = @expr()  
        return {
          type: "assignment", symbol: subject.token, value: node,
          tracking: { start: subject.tracking.start, end: node.tracking.end }
        }

  execute: () =>
    if @lexer.peek()?.type is "symbol"
      subject = @lexer.next()
      params = []
      while @lexer.peek()? and @lexer.peek().token != "\n"
        expr = @tidbit()
        if expr? and expr.type != "operator"
          params.push expr
        else
          @lexer.back()
          break
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

