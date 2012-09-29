# Interpreter

clc =
  green: (a) -> a
  blue:  (a) -> a
  red:   (a) -> a

Context = require('./context')
Lexer = require('./lexer')
Parser = require('./parser')

class Interpreter
  constructor: () ->
    @context = new Context()

  lex: (code) ->
    # make lexer
    l = Lexer(code)
    r = []
    while n = l.next()
      n

  parse: (code) ->
    p = Parser(Lexer(code).cursor())
    while n = p.next()
      n

  eval: (code) ->
    @context.myvar = "1"

  print: (list, indent = "") ->
    (for node in list
      head = "#{indent}(#{clc.green(node.type)}"
      if node.type is "block"
        "#{head}\n#{@print(node.tree,indent+"  ")}\n#{indent})"
      else if node.type is "function"
        "#{head}\n#{@print([node.body],indent+"  ")}\n#{indent})"
      else if node.type is "assignment" or node.type is "property_assignment"
        "#{head} #{clc.blue("#{node.symbol}")}\n#{@print([node.value],indent+"  ")}\n#{indent})" 
      else if node.type is "literal"
        "#{head} #{clc.red(node.token)})"
      else
        "#{head} '#{node.token}')"
    ).join "\n"

module.exports = Interpreter
