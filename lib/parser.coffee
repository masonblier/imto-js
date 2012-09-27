# Parser

Lexer = require './lexer'

# wrapped in a function to give private instance scope
Parser = (lexer) ->
  class ParserClass
    constructor: (@lexer) ->
      
    all: () ->
      while n = @next()
        n
    next: () ->
      subject = @lexer.next()
      subject = @lexer.next() while subject?.type is "linefeed"
      @expr(subject)

    expr: (subject) ->
      @block(subject) or 
      @function(subject) or
      @parenclosure(subject) or
      @assignment(subject) or 
      subject

    parenclosure: (subject) ->
      if subject?.token is "("

        inner = @expr(@lexer.next())
        if @lexer.peek()?.token is ")"
          @lexer.next()
          return inner
        else
          throw new Error "Invalid syntax"

    block: (subject) ->
      if subject?.type is "block"
        return {type: "block", tree: Parser(Lexer(subject.source)).all()}
      if subject?.type is "linefeed"
        if @lexer.peek()?.type is "block"
          n = @lexer.next()
          return {type: "block", tree: Parser(Lexer(n.source)).all()}

    function: (subject) ->
      if subject?.type is "function"
        return {type: "function", body: @expr(@lexer.next())}

    assignment: (subject) ->
      @property_assignment(subject) or
      @local_assignment(subject)

    property_assignment: (subject) ->
      if subject?.type is "symbol"
        n = @lexer.peek()
        if n?.token is ":"
          return {type: "property_assignment", symbol: subject.token, value: @expr(@lexer.next(2))}
      return null

    local_assignment: (subject) ->
      if subject?.type is "symbol"
        n = @lexer.peek()
        if n?.token is "="
          return {type: "assignment", symbol: subject.token, value: @expr(@lexer.next(2))}

  return new ParserClass(lexer)

module.exports = Parser
