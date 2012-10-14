# cursor 

class Cursor
  # constructor
  constructor: (@subject) ->
    @idx = -1
    
  # all tokens
  all: () =>
    while t = @next()
      t

  # next (memoized)
  next: (i=1) =>
    @subject.at(@idx += i)

  # back up a token
  back: (i=1) =>
    @subject.at(@idx -= i)

  # peak ahead
  peek: (i=1) =>
    @subject.at(@idx + i)

  # peak behind
  prev: (i=1) =>
    @subject.at(@idx - i)

module.exports = Cursor