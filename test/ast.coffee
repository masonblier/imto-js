redl = require('../')

# A short example ast
# statements:
#   [
#     { 
#       type: 'assignment',
#       left: 'symbol',
#       right:
#         type: 'literal'
#         value: 2
#     },
#     {
#       type: 'execute',
#       target:
#         type: 'function',
#         signature: 'a, b, c'
#         source: "some block"
#     }
#   ]

describe 'ast', ->
  it 'simple assignment', ->
    lexer = redl.Lexer('myVar = 2')
    node = redl.Node.read(lexer)
    node.type.should.equal 'assignment'
    node.symbol.should.equal 'myVar'
    node.node.type.should.equal 'literal'
    node.node.value.should.equal 2.0