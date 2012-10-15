# cursor 

class Cursor
  # constructor
  constructor: () ->
    @index = -1
    
  # all tokens
  all: () =>
    while t = @next()
      t

  # next (memoized)
  next: (i=1) =>
    @at(@index += i)

  # back up a token
  back: (i=1) =>
    @at(@index -= i)

  # peak ahead
  peek: (i=1) =>
    @at(@index + i)

  # peak behind
  prev: (i=1) =>
    @at(@index - i)

module.exports = Cursor
