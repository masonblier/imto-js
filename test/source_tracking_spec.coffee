redl = require('../src/redl')

lex = (str) -> new redl.Interpreter().lex(str)
parse = (str) -> new redl.Interpreter().parse(str)

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
    ast.next().tracking.start.should.eql { line: 0, column: 11, char: '\n'}
    ast.peek().type.should.eql "block"
    ast.peek().tracking.start.should.eql { line: 1, column: 0, char: ' ' }
    ast.next().tracking.end.should.eql   { line: 2, column: 4, char: '+' }
    ast.next().tracking.start.should.eql { line: 2, column: 5, char: '\n' }
    ast.peek().tracking.start.should.eql { line: 3, column: 0, char: '(' }
    ast.next().tracking.end.should.eql   { line: 3, column: 3, char: '>' }
    ast.peek().tracking.start.should.eql { line: 3, column: 4, char: '"' }
    ast.next().tracking.end.should.eql   { line: 3, column: 10, char: '"' }
    ast.next().tracking.start.should.eql { line: 3, column: 11, char: '\n' }

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
    subast.next().tracking.end.should.eql   {line: 0, column: 4, char: "n" }
    subast.peek().tracking.start.should.eql {line: 0, column: 5, char: "[" }
    subast.next().tracking.end.should.eql   {line: 0, column: 20, char: "]" }

    subast.peek().tracking.start.should.eql {line: 0, column: 21, char: "(" }
    subast.next().tracking.end.should.eql   {line: 0, column: 22, char: ")" }

    subast.next().tracking.start.should.eql {line: 1, column: 0, char: "i" }
    subast.next().tracking.end.should.eql   {line: 1, column: 2, char: "+" }
