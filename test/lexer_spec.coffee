redl = require('../src/redl')

describe 'lexer', ->  

  describe 'token types', ->

    it 'symbols', ->
      cursor = redl.Lexer("this_is_a_token ").cursor()

      node = cursor.next()
      node.token.should.eql 'this_is_a_token'
      node.type.should.eql 'symbol'

    it 'literals', ->
      cursor = redl.Lexer("2.0 'hi'").cursor()

      first = cursor.next()
      first.token.should.eql '2.0'
      first.type.should.eql 'literal' 
      first.value.should.eql 2

      second = cursor.next()
      second.token.should.eql "'hi'"
      second.type.should.eql 'literal'
      second.value.should.eql 'hi'

    it 'operators', ->
      tests = ['+=', '%', '(', ')']
      cursor = redl.Lexer(tests.join ' ').cursor()
      for op in tests
        next = cursor.next()
        next.token.should.eql op
        next.type.should.eql 'operator'

    it 'function signature', ->
      cursor = redl.Lexer("( a , b )   ->  ").cursor()
      sig = cursor.next()
      sig.paramList.should.have.length(2)
      sig.paramList.should.include 'a'
      sig.paramList[1].should.eql 'b'
      sig.type.should.eql 'function'

    it 'block :: curly bracket delimited', ->
      cursor = redl.Lexer("symb { this_is_a_block } 'post block'").cursor()
      # random other tokens so that we're not always trying a clean slate
      node = cursor.next()
      node.type.should.eql 'symbol'
      # block
      node = cursor.next()
      node.source.should.eql 'this_is_a_block '
      node.type.should.eql 'block'
      # check if post-block node still parses right
      node = cursor.next()
      node.value.should.eql "post block"
      node.type.should.eql 'literal'

    it 'bracketted indent formatter test', ->
      cursor = redl.Lexer("{   \n  this is\n    an indent\n  test\n}").cursor()
      node = cursor.next()
      node.source.should.match /^this is/
      node.source.should.match /^  an indent/m
      node.type.should.eql 'block'

    it 'block :: indentation delimited', ->
      cursor = redl.Lexer("\n'this is'\n  a 'block'\n  that.should 'get all of this'\nbut not this\n").cursor()
      # first line
      node = cursor.next()
      node.value.should.eql "this is"
      # line feed
      node = cursor.next()
      node.token.should.eql '\n'
      # the block
      node = cursor.next()
      node.type.should.eql 'block'
      node.source.should.match /^a/
      node.source.should.match /^that\.should/m
      node.source.should.not.match /but.*\!this/
      # line feed
      node = cursor.next()
      node.token.should.eql '\n'
      # last line
      node = cursor.next()
      node.token.should.eql 'but'
      node = cursor.next()
      node.token.should.eql 'not'
      node = cursor.next()
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
    cursor = redl.Lexer(input).cursor()
    # first line
    node = cursor.next()
    node.token.should.eql 'myObj'
    node.type.should.eql 'symbol'
    node = cursor.next()
    node.token.should.eql '='
    node.type.should.eql 'operator'
    node = cursor.next()
    node.type.should.eql 'linefeed'
    # block and indentation test
    node = cursor.next()
    node.type.should.eql 'block'
    block = node.source
    block.should.match /^this_var/m
    block.should.match /^@this_method/m
    block.should.match /^  return/m
    block.should.match /^@$/m
    node = cursor.next()
    node.type.should.eql 'linefeed'
    # last line
    node = cursor.next()
    node.token.should.eql 'myObj.this_method'
    node.type.should.eql 'symbol'

    # test the block
    cursor = redl.Lexer(block).cursor()
    node = cursor.next()
    node.token.should.eql 'this_var'
    node = cursor.next() # =
    node = cursor.next() # 'myValue'
    node = cursor.next() # \n
    node = cursor.next() # @this_method
    node.token.should.eql '@this_method'
    node.type.should.eql 'symbol'
    node = cursor.next() # =
    node = cursor.next() # () ->
    node.type.should.eql 'function'
    node.paramList.should.have.length 0
    node = cursor.next() # linefeed
    node = cursor.next() # block
    node.type.should.eql 'block'
    node = cursor.next() # \n
    node.type.should.eql 'linefeed'
    node = cursor.next() # @
    node.token.should.eql '@'
    node.type.should.eql 'symbol'

  it 'isolate parenthesis lexer bug', ->
    cursor = redl.Lexer("( 2) ").cursor()
    node = cursor.next()
    node.token.should.eql '('
    node = cursor.next()
    node.type.should.eql 'literal'
    node.token.should.eql '2'
    node = cursor.next()
    node.token.should.eql ')'



