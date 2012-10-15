redl = require('../src/redl')

parse = (str) -> new redl.Parser(new redl.Lexer(str))

describe 'parser', ->

  it 'parenclosure', ->
    parse(" ( 2) ").next().type.should == 'literal'

  it 'block', ->
    list = parse("this\n  is_a \"block\"\nout").all()
    list[0].type.should.eql 'symbol'
    list[1].type.should.eql 'block'
    sublist = parse(list[1].source).all()
    sublist[0].type.should.eql 'symbol'
    sublist[1].type.should.eql 'string'
    list[2].type.should.eql 'symbol'

  it "function", ->
    parse("()->3").next().type.should.eql 'function'

  it 'property_assignment', ->
    parse("p: 7").next().type.should.eql 'property_assignment'

  it 'local_assignment', ->
    parse("a = 7").next().type.should.eql 'assignment'
