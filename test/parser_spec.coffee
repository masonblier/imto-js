imto = require('../src')

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

  describe 'functions', ->
    it "parses functions", ->
      parse("()->3").next().type.should.eql 'function'

    it 'have signature', ->
      node = parse("(a, b, c)->a+b+c").next()
      node.signature.should.eql 'a, b, c'

  it 'hash_assignment', ->
    parse("p: 7").next().type.should.eql 'hash_assignment'

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

  describe '. operator', ->
    it 'parses left to right', ->
      node = parse("this.is.a.test").next()
      node.type.should.eql 'operator'
      node.operator.should.eql '.'
      node.left.type.should.eql 'operator'
      node.left.left.type.should.eql 'operator'
      node.left.left.left.symbol.should.eql 'this'
      node.left.left.right.symbol.should.eql 'is'
      node.left.right.symbol.should.eql 'a'
      node.right.symbol.should.eql 'test'

    it 'with expr in it', ->
      node = parse("(expr).prop").next()
      node.type.should.eql 'operator'
      node.left.type.should.eql 'block'
      node.operator.should.eql "."
      node.right.type.should.eql 'execute'

    it 'can properly nest with other operators', ->
      node = parse("a.b + a.c").next()
      node.type.should.eql 'operator'
      node.operator.should.eql '+'
      node.left.operator.should.eql '.'
      node.right.operator.should.eql '.'
      node.left.left.symbol.should.eql 'a'
      node.left.right.symbol.should.eql 'b'
      node.right.left.symbol.should.eql 'a'
      node.right.right.symbol.should.eql 'c'

    it 'harder example', ->
      node = parse("(a+b).d.(c+d.b)").next()
      node.type.should.eql 'operator'
      node.operator.should.eql '.'
      node.left.operator.should.eql '.'
      node.left.left.type.should.eql 'block'
      node.left.right.symbol.should.eql 'd'
      node.right.type.should.eql 'block'
      ablk = parse(node.left.left.source).next()
      ablk.operator.should.eql '+'
      ablk.left.symbol.should.eql 'a'
      ablk.right.symbol.should.eql 'b'
      bblk = parse(node.right.source).next()
      bblk.operator.should.eql '+'
      bblk.left.symbol.should.eql 'c'
      bblk.right.operator.should.eql '.'
      bblk.right.left.symbol.should.eql 'd'
      bblk.right.right.symbol.should.eql 'b'

  describe 'operators', ->
    it ' left to right for flat precedence', ->
      node = parse("a + b + c").next()
      node.type.should.eql 'operator'
      node.left.type.should.eql 'operator'
      node.right.type.should.eql 'execute'
      node.left.left.symbol.should.eql 'a'
      node.left.right.symbol.should.eql 'b'
      node.right.symbol.should.eql 'c'

  describe 'property assignment & hashes', ->
    it 'creates a new block when hashes are seperated by commas in a param list', ->
      parser = parse("fn a:1, b:2")
      node = parser.next()
      (parser.peek()==undefined).should.eql true
      node.type.should.eql 'execute'
      node.symbol.should.eql 'fn'
      node.params.length.should.eql 1

