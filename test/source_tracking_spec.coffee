{Parser, Lexer} = require('../src')

lex = (str) -> new Lexer(str)
parse = (str, offset) -> (new Parser(new Lexer(str, offset)))

describe "source tracking", ->
  describe 'lexer', ->

    it 'has line and column info', ->
      ast = lex("while i < 0\n  chain[chain.length-i]()\n  i++\n()->\"hello\"\n")
      ast.peek().tracking.start.line.should == 0
      ast.peek().tracking.end.line.should == 0
      ast.peek().tracking.start.column.should == 0
      ast.peek().tracking.end.column.should == 4
      ast.next().token.should == "while"
      ast.next().tracking.start.should.eql { line: 0, column: 6, char: 'i'}
      ast.next().tracking.start.should.eql { line: 0, column: 8, char: '<'}
      ast.next().tracking.start.should.eql { line: 0, column: 10, char: '0'}
      ast.peek().type.should.eql "block"
      ast.peek().tracking.start.should.eql { line: 1, column: 2, char: 'c' }
      ast.next().tracking.end.should.eql   { line: 2, column: 4, char: '+' }
      ast.next().tracking.start.should.eql { line: 2, column: 5, char: '\n' }
      ast.peek().tracking.start.should.eql { line: 3, column: 0, char: '(' }
      ast.next().tracking.end.should.eql   { line: 3, column: 3, char: '>' }
      ast.peek().tracking.start.should.eql { line: 3, column: 4, char: '"' }
      ast.next().tracking.end.should.eql   { line: 3, column: 10, char: '"' }
      ast.next().tracking.start.should.eql { line: 3, column: 11, char: '\n' }

    it 'blocks columns include indents', ->
      ast = lex("  my block")
      ast.peek().tracking.start.should.eql { line: 0, column: 2, char: 'm' }
      ast.peek().tracking.end.should.eql { line: 0, column: 9, char: 'k' }

  describe 'parser', ->

    it 'has line and column info', ->
      ast = parse("r: q = () ->\n  chain[chain.length-i]()\n  i++\n\"hello\"\n")
      ast.peek().tracking.start.should.eql {line: 0, column: 0, char: "r" }
      ast.next().tracking.end.should.eql   { line: 2, column: 4, char: "+" }

      ast.peek().tracking.start.should.eql { line: 3, column: 0, char: '"'}
      ast.next().tracking.end.should.eql   { line: 3, column: 6, char: '"'}

      ast.at(0).value.tracking.start.should.eql {line: 0, column: 3, char: "q" }
      ast.at(0).value.tracking.end.should.eql   { line: 2, column: 4, char: "+" }

      subast = parse(ast.at(0).value.value.body.source)
      subast.peek().tracking.start.should.eql {line: 0, column: 0, char: "c" }
      subast.next().tracking.end.should.eql   {line: 0, column: 20, char: "]" }
      subast.peek().tracking.start.should.eql {line: 0, column: 21, char: "(" }
      subast.next().tracking.end.should.eql   {line: 0, column: 22, char: ")" }
      
      subast.peek().tracking.start.should.eql {line: 1, column: 0, char: "i" }
      subast.next().tracking.end.should.eql   {line: 1, column: 2, char: "+" }

    it 'things inside blocks still have correct source line and columns', ->
      ast = parse("this\n  is \"just a test\"\n  just (like + yesterday)\n\"or tomorrow\"")
      ast.peek().type.should.eql 'execute'
      ast.peek().tracking.start.should.eql      {line: 0, column: 0, char: 't' }
      ast.next().tracking.end.should.eql        {line: 2, column: 24, char: ')'}
      ast.peek().type.should.eql 'string'
      ast.peek().tracking.start.should.eql      {line: 3, column: 0, char: '\"' }
      ast.next().tracking.end.should.eql        {line: 3, column: 12, char: '\"'}

      subast = parse(ast.at(0).params[0].source, tracking: ast.at(0).params[0].tracking)
      subast.peek().type.should.eql 'execute'
      subast.peek().tracking.start.should.eql   {line: 1, column: 2, char: 'i'}
      subast.peek().tracking.end.should.eql     {line: 1, column: 17, char: '\"'}
      subast.next().params[0].tracking.start.should.eql {line: 1, column: 5, char: "\""}

  it "tracks execute statement", ->
    node = parse("a b").next()
    node.type.should.eql 'execute'
    node.tracking.start.should.eql { line: 0, column: 0, char: 'a'}
    node.tracking.end.should.eql { line: 0, column: 2, char: 'b'}
    node.params[0].symbol.should.eql 'b'
    node.params[0].tracking.start.should.eql { line: 0, column: 2, char: 'b'}
    node.params[0].tracking.end.should.eql { line: 0, column: 2, char: 'b'}