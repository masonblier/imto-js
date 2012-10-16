imto = require('../src')

parse = (str) -> new imto.Parser(new imto.Lexer(str))

describe 'parser', ->

  it 'parenclosure', ->
    parse(" ( 2) ").next().type.should == 'literal'

  it 'block', ->
    list = parse("this\n  is_a \"block\"\nout").all()
    list[0].type.should.eql 'execute'
    list[0].params[0].type.should.eql 'block'
    sublist = parse(list[0].params[0].source).all()
    sublist[0].type.should.eql 'execute'
    sublist[0].params[0].type.should.eql 'string'
    list[1].type.should.eql 'execute'
    list[1].params.should.eql []

  it "function", ->
    parse("()->3").next().type.should.eql 'function'

  it 'property_assignment', ->
    parse("p: 7").next().type.should.eql 'property_assignment'

  it 'local_assignment', ->
    parse("a = 7").next().type.should.eql 'assignment'

  it "execute statement", ->
    node = parse("a b").next()
    node.type.should.eql 'execute'
    node.symbol.should.eql 'a'
    (node.operator==undefined).should.eql true
    node.params[0].symbol.should.eql 'b'

  it 'execute with operator', ->
    node = parse("a + b").next()
    node.type.should.eql 'execute'
    node.operator.should.eql '+'


  it 'self operator', ->
    node = parse("a++").next()
    node.type.should.eql 'execute'
    node.operator.should.eql '++'
    (node.value==undefined).should.eql true
    node.symbol.should.eql "a"