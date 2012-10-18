imto = require('../src')

p = (node) -> process.stdout.write "\n#{node}\n"
parse = (str) -> new imto.Parser(new imto.Lexer(str))

describe 'parser', ->

  it 'parenclosure', ->
    n = parse(" ( 2) ").next()
    n.type.should == 'literal'

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

  it 'operator statement', ->
    node = parse("a + b").next()
    node.type.should.eql 'operator'
    node.operator.should.eql '+'


  it 'self operator', ->
    node = parse("a++").next()
    node.type.should.eql 'operator'
    node.operator.should.eql '++'
    node.left.symbol.should.eql "a"

  it 'dot operator', ->
    node = parse("this.is.a.test").next()
    node.type.should.eql 'operator'
    node.operator.should.eql '.'
    node.left.type.should.eql 'operator'
    node.left.left.type.should.eql 'operator'
    node.left.left.left.symbol.should.eql 'this'
    node.left.left.right.symbol.should.eql 'is'
    node.left.right.symbol.should.eql 'a'
    node.right.symbol.should.eql 'test'

  it 'dot operator with expr in it', ->
    node = parse("(expr).prop").next()
    node.type.should.eql 'operator'
    node.left.type.should.eql 'block'
    node.operator.should.eql "."
    node.right.type.should.eql 'execute'

  it 'evaluate left to right for flat precedence', ->
    node = parse("a + b + c").next()
    node.type.should.eql 'operator'
    node.left.type.should.eql 'operator'
    node.right.type.should.eql 'execute'
    node.left.left.symbol.should.eql 'a'
    node.left.right.symbol.should.eql 'b'
    node.right.symbol.should.eql 'c'
