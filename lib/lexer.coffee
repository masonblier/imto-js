# Lexer

WHITESPACE = [' ', '\t']
OPERATORS = ['=','+','-','*','/','<','>','%','&','(',')','[',']','^','@',':','?','.']

Lexer = (str) ->
  class LexerClass
    c = 0
    length = 0
    input = ''

    special = []

    # constructor
    constructor: (str) ->
      c = 0
      input = str
      length = input.length
      replaceSpecials()

    # find and replace special sections
    replaceSpecials = () ->
      while (match = /\((,|\t| |([a-zA-Z]|_)?([a-zA-Z0-9]|_)*)*\)(\t| )*->/.exec input) != null
        i = special.length
        input = input.replace(match[0],"{#{i}}")
        paramList = []
        submatch = /\((.*)\)/.exec match[0]
        params = submatch[1].split ','
        for p in params
          p.trim()
          paramList.push p
        special[i] = { type: 'function', 'token': match[0], paramList: paramList }


    # next token
    next: () ->
      x = input[c]
      c += 1
      buffer = ''

      # skip whitespace
      while x in WHITESPACE
        x = input[c]
        c += 1

      # match special
      if x == '{'
        loop
          x = input[c]
          c++
          break unless c < length and x != '}'
          buffer += x
        index = parseInt(buffer)
        return special[index]


      # match operator
      if x in OPERATORS
        loop
          buffer += x
          x = input[c]
          c += 1
          break unless c < length
          break unless x in OPERATORS
        return {
          type: 'operator',
          token: buffer
        }

      # match symbol
      if /([a-zA-Z]|_|\.)/.test x
        token = ''
        loop
          break unless c < length
          break unless /([a-zA-Z0-9]|_)/.test x
          token += x
          x = input[c]
          c++
        return {
          type: 'symbol',
          token: token
        }

      # match numbers
      if /([0-9])/.test x
        value = ''
        loop
          break unless c < length && /([0-9]|\.)/.test x
          value += x
          x = input[c]
          c++
        return {
          type: 'literal',
          token: value,
          value: parseFloat(value)
        }

      # match strings
      if x is "'" or x is '"'
        sym = x
        value = ''
        loop
          break unless c < length
          x = input[c]
          c++
          break if x == sym
          value += x 
        
        return {
          type: 'literal',
          token: sym+value+sym,
          value: value
        }

      # unknown value
      return { type: 'none' }

  # this is retarded
  return new LexerClass str


module.exports = Lexer
