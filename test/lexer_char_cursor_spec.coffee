redl = require('../src/redl')

make_cursor = (str) -> new redl.Lexer.CharCursor(str)

describe 'Lexer.CharCursor', ->  

  it 'tracks line and column info', ->
    cursor = make_cursor("this is\na test")
    cursor.at( 0).should.eql column: 0, line: 0, char: "t"
    cursor.at( 1).should.eql column: 1, line: 0, char: "h"
    cursor.at( 2).should.eql column: 2, line: 0, char: "i"
    cursor.at( 3).should.eql column: 3, line: 0, char: "s"
    cursor.at( 4).should.eql column: 4, line: 0, char: " "
    cursor.at( 5).should.eql column: 5, line: 0, char: "i"
    cursor.at( 6).should.eql column: 6, line: 0, char: "s"
    cursor.at( 7).should.eql column: 7, line: 0, char: "\n"
    cursor.at( 8).should.eql column: 0, line: 1, char: "a"
    cursor.at( 9).should.eql column: 1, line: 1, char: " "
    cursor.at(10).should.eql column: 2, line: 1, char: "t"
    cursor.at(11).should.eql column: 3, line: 1, char: "e"
    cursor.at(12).should.eql column: 4, line: 1, char: "s"
    cursor.at(13).should.eql column: 5, line: 1, char: "t"
    (cursor.at(14) == undefined).should.eql true

  it 'can give indentation level of an index', ->
    cursor = make_cursor("this is\n  a test\n  for\n    my\nindenting")
    cursor.indent(0).should.eql 0
    cursor.indent(8).should.eql 2
    cursor.indent(17).should.eql 2
    cursor.indent(23).should.eql 4
    cursor.indent(30).should.eql 0

