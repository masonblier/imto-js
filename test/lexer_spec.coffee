imto = require('../src')

lex = (str) -> new imto.Lexer(str)

describe 'lexer', ->  
  count = -1

  beforeEach ->

  describe 'token types', ->

    it 'symbols', ->
      cursor = lex("this_is_a_token ")

      node = cursor.next()
      node.token.should.eql 'this_is_a_token'
      node.type.should.eql 'symbol'

    it 'number and string', ->
      cursor = lex("2.0 'hi'")

      first = cursor.next()
      first.token.should.eql '2.0'
      first.type.should.eql 'number' 
      first.value.should.eql 2

      second = cursor.next()
      second.token.should.eql "'hi'"
      second.type.should.eql 'string'
      second.value.should.eql 'hi'

    it 'operators', ->
      tests = ['+=', '%', '/', '&=', '.']
      cursor = lex(tests.join ' ')
      for op in tests
        next = cursor.next()
        next.token.should.eql op
        next.type.should.eql 'operator'

    it 'function signature', ->
      cursor = lex("( a , b )   ->  ")
      sig = cursor.next()
      sig.source.should.eql 'a , b '
      sig.type.should.eql 'function'

    it 'double arrow function', ->
      cursor = lex("() => ")
      sig = cursor.next()
      sig.source.should.eql ""
      sig.type.should.eql 'function'

    it 'block :: curly bracket delimited', ->
      cursor = lex("symb { this_is_a_block } 'post block'")
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
      node.type.should.eql 'string'

    it 'bracketted indent formatter test', ->
      cursor = lex("{   \n  this is\n    an indent\n  test\n}")
      node = cursor.next()
      node.source.should.match /^this is/
      node.source.should.match /^  an indent/m
      node.type.should.eql 'block'

    it 'block :: indentation delimited', ->
      cursor = lex("'this is'\n  a 'block'\n  that.should 'get all of this'\nbut not this\n")
      # first line
      node = cursor.next()
      node.value.should.eql "this is"

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
    cursor = lex(input)
    # first line
    node = cursor.next()
    node.token.should.eql 'myObj'
    node.type.should.eql 'symbol'
    node = cursor.next()
    node.token.should.eql '='
    node.type.should.eql 'operator'
    # block and indentation test
    node = cursor.next()
    node.type.should.eql 'block'
    block = node.source
    block.should.match /^this_var/m
    block.should.match /^@this_method/m
    block.should.match /^  return/m
    block.should.match /^@$/m
    # last line
    node = cursor.next()
    node.type.should.eql "linefeed"
    node = cursor.next()
    node.token.should.eql 'myObj'
    node.type.should.eql 'symbol'
    node = cursor.next()
    node.token.should.eql '.'
    node.type.should.eql 'operator'
    node = cursor.next()
    node.token.should.eql 'this_method'
    node.type.should.eql 'symbol'
    # test the block
    cursor = lex(block)
    node = cursor.next()
    node.token.should.eql 'this_var'
    node = cursor.next() # =
    node = cursor.next() # 'myValue'
    node = cursor.next() # \n
    node.type.should.eql 'linefeed'
    node = cursor.next() # @this_method
    node.token.should.eql '@this_method'
    node.type.should.eql 'symbol'
    node = cursor.next() # =
    node = cursor.next() # () ->
    node.type.should.eql 'function'
    node.source.should.eql ''
    node = cursor.next() # block
    node.type.should.eql 'block'
    node = cursor.next() # \n
    node.type.should.eql 'linefeed'
    node = cursor.next() # @
    node.token.should.eql '@'
    node.type.should.eql 'symbol'

  it 'isolate parenthesis lexer bug', ->
    cursor = lex("( 2) ")
    node = cursor.next()
    node.token.should.eql '( 2)'
    node.source.should.eql '2'
    node.type.should.eql 'block'
    node = cursor.next()
    (node == null).should.eql true

  it 'can parse through newlines in a block', ->
    cursor = lex("\nmyObj = \n\n  \"this is only a test\"\n")
    node = cursor.next()
    node.token.should.eql 'myObj'
    node = cursor.next()
    node.type.should.eql 'operator'
    node = cursor.next()
    node.type.should.eql 'block'
    node.source.should.eql "\"this is only a test\""

  it 'parens are not operators', ->
    cursor = lex("(a).(b)")
    node = cursor.next()
    node.type.should.eql 'block'
    node = cursor.next()
    node.type.should.eql 'operator'
    node.token.should.eql '.'
    node = cursor.next()
    node.type.should.eql 'block'
    node.source.should.eql 'b'

  it 'no trailing commas in numbers', ->
    cursor = lex("393,393,")
    node = cursor.next()
    node.type.should.eql 'number'
    node.value.should.eql 393393
    node = cursor.next()
    node.type.should.eql 'comma'
