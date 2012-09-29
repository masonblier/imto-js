# Parser

Lexer = require './lexer'

# wrapped in a function to give private instance scope
Parser = (lexer) ->
  class ParserClass
    constructor: (@cursor) ->
      
    all: () ->
      while n = @next()
        n
    next: () ->
      subject = @cursor.next()
      subject = @cursor.next() while subject?.type is "linefeed"
      @expr(subject)

    expr: (subject) ->
      @block(subject) or 
      @function(subject) or
      @parenclosure(subject) or
      @assignment(subject) or 
      subject

    parenclosure: (subject) ->
      if subject?.token is "("
        inner = @expr(@cursor.next())
        if @cursor.peek()?.token is ")"
          @cursor.next()
          return inner
        else
          throw new Error "Invalid syntax"

    block: (subject) ->
      if subject?.type is "block"
        return {type: "block", tree: Parser(Lexer(subject.source).cursor()).all()}
      if subject?.type is "linefeed"
        if @cursor.peek()?.type is "block"
          n = @cursor.next()
          return {type: "block", tree: Parser(Lexer(n.source).cursor()).all()}

    function: (subject) ->
      if subject?.type is "function"
        return {type: "function", body: @expr(@cursor.next())}

    assignment: (subject) ->
      @property_assignment(subject) or
      @local_assignment(subject)

    property_assignment: (subject) ->
      if subject?.type is "symbol"
        n = @cursor.peek()
        if n?.token is ":"
          return {type: "property_assignment", symbol: subject.token, value: @expr(@cursor.next(2))}
      return null

    local_assignment: (subject) ->
      if subject?.type is "symbol"
        n = @cursor.peek()
        if n?.token is "="
          return {type: "assignment", symbol: subject.token, value: @expr(@cursor.next(2))}

  return new ParserClass(lexer)

module.exports = Parser
