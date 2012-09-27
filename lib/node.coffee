# AST Generator, the "node reader"

# half-assed asts
# created on the fly

# assumes 'start of statement'
read = (lexer) ->
  subject = null
  t = lexer.next() 
  # skip newlines
  t = lexer.next() while t? and t.type is 'linefeed'
  # end of stream
  unless t?
    return null
  # symbol
  if t.type is 'symbol'
    subject = t
    t = lexer.next()
    if t.type is 'operator' and t.token is '='
      r = read(lexer)
      return {
        type: 'assignment',
        symbol: subject.token,
        node: r
      }
  else if t.type is 'literal'
    subject = t
    return {
      type: t.type
      value: t.value
    }

module.exports.read = read
