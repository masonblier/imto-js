redl = require('../')

describe 'lexer', ->

  describe 'identifies single token ::', ->

    it 'symbols', ->
      lexer = new redl.Lexer("this_is_a_token ")

      node = lexer.next()
      node.type.should.equal 'symbol'
      node.token.should.equal 'this_is_a_token'

    it 'literals', ->
      lexer = new redl.Lexer("2.0 'hi'")

      first = lexer.next()
      first.type.should.equal 'literal' 
      first.token.should.equal '2.0'
      first.value.should.equal 2

      second = lexer.next()
      second.type.should.equal 'literal'
      second.token.should.equal "'hi'"
      second.value.should.equal 'hi'

    it 'operators', ->
      tests = ['+=', '%', '(', ')']
      lexer = new redl.Lexer(tests.join ' ')
      for op in tests
        next = lexer.next()
        next.type.should.equal 'operator'
        next.token.should.equal op

    it 'function signature', ->
      lexer = new redl.Lexer("(a,b) -> ")
      sig = lexer.next()
      sig.type.should.equal 'function'
      sig.paramList.should.have.length(2)
      sig.paramList.should.include 'a'
      sig.paramList[1].should.equal 'b'
