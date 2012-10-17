# cursor 

class Cursor
  # constructor
  constructor: (@subject) ->
    @subject = @ unless @subject
    @index = 0
    
  # all tokens
  all: () =>
    while t = @next()
      t

  # clone
  clone: () =>
    return new Cursor @

  # next (memoized)
  next: (i=1) =>
    @at((@index += i)-1)

  # back up a token
  back: (i=1) =>
    @at((@index -= i)-1)

  # peak ahead
  peek: (i=1) =>
    @at((@index + i)-1)

  # peak behind
  prev: (i=1) =>
    @at((@index - i)-1)

module.exports = Cursor
