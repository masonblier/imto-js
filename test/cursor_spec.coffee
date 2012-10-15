redl = require('../src/redl')

describe 'cursor', ->
    beforeEach ->
      @cursor = (new redl.Lexer("one two three four"))

    it 'should get the #next', ->
      @cursor.next().token.should.eql 'one'
      @cursor.next().token.should.eql 'two'
      @cursor.next().token.should.eql 'three'
      @cursor.next().token.should.eql 'four'

    it 'should go #next [moves]', ->
      @cursor.next().token.should.eql 'one'
      @cursor.next(2).token.should.eql 'three'
      @cursor.next().token.should.eql 'four'

    it 'should go #back', ->
      @cursor.next().token.should.eql 'one'
      @cursor.next().token.should.eql 'two'
      @cursor.back()
      @cursor.next().token.should.eql 'two'
      @cursor.next().token.should.eql 'three'
      @cursor.next().token.should.eql 'four'

    it 'should #peek', ->
      @cursor.next().token.should.eql 'one'
      @cursor.peek().token.should.eql 'two'
      @cursor.next().token.should.eql 'two'
      @cursor.back()
      @cursor.peek().token.should.eql 'two'
      @cursor.next().token.should.eql 'two'

    it 'should look #prev', ->
      @cursor.next().token.should.eql 'one'
      @cursor.next().token.should.eql 'two'
      @cursor.prev().token.should.eql 'one'
      @cursor.back()
      @cursor.next().token.should.eql 'two'
      @cursor.prev().token.should.eql 'one'
