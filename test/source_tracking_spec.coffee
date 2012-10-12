redl = require('../src/redl')

parse = (str) ->
  new redl.Interpreter().parse(str)

describe 'lexer', ->

  xit 'has line and column info', ->
    ast = parse("while i < 0\n  chain[chain.length-i]()\n  i++")
    ast[0].tracking.line.first.should == 0
    ast[0].tracking.line.last.should == 0
    ast[0].tracking.column.first.should == 0
    ast[0].tracking.column.last.should == 5
