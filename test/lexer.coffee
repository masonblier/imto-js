redl = require('../')

describe 'lexer', ->

  describe 'navigation', ->

    beforeEach ->
      @lexer = redl.Lexer("one two three four")

    it 'should get the #next', ->
      @lexer.next().token.should.eql 'one'
      @lexer.next().token.should.eql 'two'
      @lexer.next().token.should.eql 'three'
      @lexer.next().token.should.eql 'four'

    it 'should go #next [moves]', ->
      @lexer.next().token.should.eql 'one'
      @lexer.next(2).token.should.eql 'three'
      @lexer.next().token.should.eql 'four'

    it 'should go #back', ->
      @lexer.next().token.should.eql 'one'
      @lexer.next().token.should.eql 'two'
      @lexer.back()
      @lexer.next().token.should.eql 'two'
      @lexer.next().token.should.eql 'three'
      @lexer.next().token.should.eql 'four'

    it 'should #peek', ->
      @lexer.next().token.should.eql 'one'
      @lexer.peek().token.should.eql 'two'
      @lexer.next().token.should.eql 'two'
      @lexer.back()
      @lexer.peek().token.should.eql 'two'
      @lexer.next().token.should.eql 'two'

    it 'should look #prev', ->
      @lexer.next().token.should.eql 'one'
      @lexer.next().token.should.eql 'two'
      @lexer.prev().token.should.eql 'one'
      @lexer.back()
      @lexer.next().token.should.eql 'two'
      @lexer.prev().token.should.eql 'one'
      

  describe 'token types', ->

    it 'symbols', ->
      lexer = redl.Lexer("this_is_a_token ")

      node = lexer.next()
      node.token.should.eql 'this_is_a_token'
      node.type.should.eql 'symbol'

    it 'literals', ->
      lexer = redl.Lexer("2.0 'hi'")

      first = lexer.next()
      first.token.should.eql '2.0'
      first.type.should.eql 'literal' 
      first.value.should.eql 2

      second = lexer.next()
      second.token.should.eql "'hi'"
      second.type.should.eql 'literal'
      second.value.should.eql 'hi'

    it 'operators', ->
      tests = ['+=', '%', '(', ')']
      lexer = redl.Lexer(tests.join ' ')
      for op in tests
        next = lexer.next()
        next.token.should.eql op
        next.type.should.eql 'operator'

    it 'function signature', ->
      lexer = redl.Lexer("( a , b )   ->  ")
      sig = lexer.next()
      sig.paramList.should.have.length(2)
      sig.paramList.should.include 'a'
      sig.paramList[1].should.eql 'b'
      sig.type.should.eql 'function'

    it 'block :: curly bracket delimited', ->
      lexer = redl.Lexer("symb { this_is_a_block } 'post block'")
      # random other tokens so that we're not always trying a clean slate
      node = lexer.next()
      node.type.should.eql 'symbol'
      # block
      node = lexer.next()
      node.source.should.eql 'this_is_a_block '
      node.type.should.eql 'block'
      # check if post-block node still parses right
      node = lexer.next()
      node.value.should.eql "post block"
      node.type.should.eql 'literal'

    it 'bracketted indent formatter test', ->
      lexer = redl.Lexer("{   \n  this is\n    an indent\n  test\n}")
      node = lexer.next()
      node.source.should.match /^this is/
      node.source.should.match /^  an indent/m
      node.type.should.eql 'block'

    it 'block :: indentation delimited', ->
      lexer = redl.Lexer("\n'this is'\n  a 'block'\n  that.should 'get all of this'\nbut not this\n")
      # first line
      node = lexer.next()
      node.value.should.eql "this is"
      # line feed
      node = lexer.next()
      node.token.should.eql '\n'
      # the block
      node = lexer.next()
      node.type.should.eql 'block'
      node.source.should.match /^a/
      node.source.should.match /^that\.should/m
      node.source.should.not.match /but.*\!this/
      # line feed
      node = lexer.next()
      node.token.should.eql '\n'
      # last line
      node = lexer.next()
      node.token.should.eql 'but'
      node = lexer.next()
      node.token.should.eql 'not'
      node = lexer.next()
      node.token.should.eql 'this'

  it 'sample code test', ->
    input =  '''
            myObj = 
              this_var = 'myValue'
              @this_method = () ->
                return this_var 'myValue'
              @
            myObj.this_method
            '''
    lexer = redl.Lexer input
    # first line
    node = lexer.next()
    node.token.should.eql 'myObj'
    node.type.should.eql 'symbol'
    node = lexer.next()
    node.token.should.eql '='
    node.type.should.eql 'operator'
    node = lexer.next()
    node.type.should.eql 'linefeed'
    # block and indentation test
    node = lexer.next()
    node.type.should.eql 'block'
    block = node.source
    block.should.match /^this_var/m
    block.should.match /^@this_method/m
    block.should.match /^  return/m
    block.should.match /^@$/m
    node = lexer.next()
    node.type.should.eql 'linefeed'
    # last line
    node = lexer.next()
    node.token.should.eql 'myObj.this_method'
    node.type.should.eql 'symbol'

    # test the block
    lexer = redl.Lexer(block)
    node = lexer.next()
    node.token.should.eql 'this_var'
    node = lexer.next() # =
    node = lexer.next() # 'myValue'
    node = lexer.next() # \n
    node = lexer.next() # @this_method
    node.token.should.eql '@this_method'
    node.type.should.eql 'symbol'
    node = lexer.next() # =
    node = lexer.next() # () ->
    node.type.should.eql 'function'
    node.paramList.should.have.length 0
    node = lexer.next() # linefeed
    node = lexer.next() # block
    node.type.should.eql 'block'
    node = lexer.next() # \n
    node.type.should.eql 'linefeed'
    node = lexer.next() # @
    node.token.should.eql '@'
    node.type.should.eql 'symbol'

  it 'isolate parenthesis lexer bug', ->
    lexer = redl.Lexer("( 2) ")
    node = lexer.next()
    node.token.should.eql '('
    node = lexer.next()
    node.type.should.eql 'literal'
    node.token.should.eql '2'
    node = lexer.next()
    node.token.should.eql ')'



