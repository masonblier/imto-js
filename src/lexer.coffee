# Lexer

WHITESPACE = [' ', '\t']
OPERATORS = ['=','+','-','*','/','<','>','%','&','(',')','[',']','^',':','?','.']

# this is a hack, its wrapped in a function so that we can have instance-level private variables
Lexer = (str) ->
  class LexerClass
    # instance variables
    c = 0
    m = -1
    input = ''

    special = []
    memos = []

    # constructor
    constructor: (str) -> 
      c = 0
      input = str
      replaceSpecials()

    # all tokens
    all: () ->
      while t = @next()
        t

    # next (memoized)
    next: (i=1) ->
      o = m+i
      while m < o
        unless memos[m+=1]
          memos[m] = next_token()
      memos[m]

    # back up a token
    back: (i=1) ->
      m-=i
      memos[m]

    # peak ahead
    peek: (i=1) ->
      o = m+i
      @next() while m < o
      m = o-i
      memos[o]

    # peak behind
    prev: (i=1) ->
      memos[m-i]


    # private


    # find and replace special sections
    replaceSpecials = () ->
      # whitespace blocks
      lines = input.split '\n'
      indent = ''
      while (not /\S/.test lines[0]) and lines.length > 1
        lines.splice(0,1)
      if imtch = /^\s+/.exec lines[0] and imtch?
        indent = (imtch)[0]

      # next step is to find indented areas and split them out
      i = 0
      l = -1
      while (i <= lines.length)
        while ( i < lines.length and (lines[i].indexOf indent is 0) and /^\s/.test lines[i].substr(indent.length) )
          if l is -1 # new indented block
            l = i
          i++
        if l >= 0
          str = lines.splice(l,i-l).join '\n'
          idx = special.length
          lines.splice(l,0,"{#{idx}}")
          special[idx] = { type: 'block', token: str, 'source': formatBlockSource(str) }
          i = l
          l = -1
        i++
      input = lines.join '\n'

      # other blocks
      i = 0
      d = 0
      l = 0
      while (i < input.length)
        if input[i] is '{'
          if d is 0 then l = i
          d += 1
        else if input[i] is '}'
          d -= 1
          if d is 0
            token = input.substr(l,i-l+1)
            if /^(\s*)\{([0-9])+\}(\s*)$/.test token
              i++
              continue
            else if (imtch = /^\{(\s*)\{([0-9])+\}(\s*)\}$/.exec token) and imtch?
              marker = '{'+imtch[2]+'}'
              input = (input.substr(0,l)+marker+input.substr(i+1))
            else
              k = special.length
              marker = "{#{k}}"
              input = (input.substr(0,l)+marker+input.substr(i+1))
              special[k] = { type: 'block', 'token': token, 'source': formatBlockSource(token) }
            i = l+marker.length
          if d <= -1
            throw 'parser stack index out of bounds'
        i += 1

      if d > 0 then throw 'parser stack unbalanced'

      # function signatures
      while (match = /\(((?:[,\t ]*[a-zA-Z_][a-zA-Z0-9_]*)+[\t ]*)?\)[\t ]*[=-]>/.exec input) != null
        i = special.length
        input = input.replace(match[0],"{#{i}}")
        paramList = []
        submatch = /\((.*)\)/.exec match[0]
        params = if /,/.test submatch[1] then submatch[1].split ',' else []
        for p in params
          paramList.push p.trim()
        special[i] = { type: 'function', 'token': match[0], paramList: paramList }

    # takes a block, formats it, and cuts indendation
    formatBlockSource = (source) ->
      work = source
      indent = ''
      if work[0] is '{' and work[work.length-1] is '}'
        work = work.substr(1,work.length-2)
      lines = work.split '\n'
      # first line empty
      while (not /\S/.test lines[0]) and lines.length > 1
        lines.splice(0,1)
      if (imtch = /^\s+/.exec lines[0]) and imtch?
        indent = imtch[0]
      
      work = (line.replace(indent,'') for line in lines).join('\n')
      return work

    # next token
    next_token = () ->
      return null if c >= input.length

      x = input[c]
      c += 1
      buffer = ''

      # skip whitespace
      while x in WHITESPACE
        x = input[c]
        c += 1

      # undefined
      if x is undefined
        return { type: 'none', token: "" }

      # match special
      if x == '{'
        loop
          x = input[c]
          c++
          break unless c < input.length and x != '}'
          buffer += x
        index = parseInt(buffer)
        return special[index]


      # match operator
      if x in OPERATORS
        loop
          buffer += x
          x = input[c]
          break unless x in OPERATORS
          c += 1
          break unless c < input.length
        return {
          type: 'operator',
          token: buffer
        }

      # match symbol
      if /([a-zA-Z_]|@|\.)/.test x
        token = ''
        loop
          token += x
          break unless c < input.length
          x = input[c]
          break unless x is '.' or /([a-zA-Z0-9_])/.test x
          c++
        return {
          type: 'symbol',
          token: token
        }

      # match numbers
      if /([0-9])/.test x
        value = ''
        loop
          value += x
          break unless c < input.length &&
          x = input[c]
          break unless /([0-9]|\.)/.test x
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
          break unless c < input.length
          x = input[c]
          c++
          break if x == sym
          value += x 
        
        return {
          type: 'literal',
          token: sym+value+sym,
          value: value
        }

      # line feed
      if x is '\n'
        return { type: 'linefeed', token: '\n' }

      # unknown value
      return { type: 'unknown' }

  return new LexerClass(str)

module.exports = Lexer
