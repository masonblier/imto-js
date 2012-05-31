redl = require('../')

describe 'lexer', ->

  describe 'identifies single token', ->

    it 'identifies symbols', ->
      lexer = new redl.Lexer("this_is_a_token")

      node = lexer.next()
      node.type.should.equal 'symbol'
      node.token.should.equal 'this_is_a_token'

    it 'identifies literals', ->
      lexer = new redl.Lexer("2.0 'hi'")

      first = lexer.next()
      first.type.should.equal 'literal' 
      first.token.should.equal '2.0'
      first.value.should.equal 2

      second = lexer.next()
      second.type.should.equal 'literal'
      second.token.should.equal "'hi'"
      second.value.should.equal 'hi'
