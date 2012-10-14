# requirements

Cursor = require "./cursor"

WHITESPACE = [' ', '\t']
OPERATORS = ['=','+','-','*','/','<','>','%','&','(',')','[',']','^',':','?','.']

class SyntaxError extends Error

class CharCursor extends Cursor
  constructor: (@input) ->
    super()
    @input = @input.replace("\r","")
    @lines = @input.split("\n")
    @line_ends = []
    @indents = []
    acc = 0
    for line in @lines
      acc += line.length
      @line_ends.push acc
      acc++
    if acc != @input.length+1
      throw new Error("Tracking went wrong #{acc}, #{@input.length+1}")

  at: (index) =>
    return undefined if index < 0 or index >= @input.length
    line = 0
    while index > @line_ends[line]
      line++
    return {
      line: line, 
      column: index - (if line > 0 then @line_ends[line-1]+1 else 0),
      char: @input[index]
    }

  indent: (index) =>
    line = 0
    while index > @line_ends[line]
      line++
    indent = if @indents[line]? then @indents[line] else 0
    if indent is 0
      indent++ while @lines[line][indent] in WHITESPACE
    indent

#
# Lexer
#

module.exports = class Lexer

  # export Lexer.CharCursor
  @CharCursor: CharCursor

  # constructor
  constructor: (@input) ->
    @char_index = 0
    @memo_index = -1
    @memos = []
    @linestart = true
    @indent = 0
    @stream = new CharCursor(@input)

  # cursor
  cursor: () =>
    new Cursor(@)

  # at
  at: (req_index) =>
    # it follows the lexer sequentially, 
    # memoizing to provide back functionality
    while @memo_index < req_index
      unless @memos[@memo_index+=1]
        @memos[@memo_index] = @next_token()
    @memos[req_index]

  # next_token
  next_token: () =>
    return null if @char_index >= @input.length

    buffer = ''

    # match indentation block
    if @stream.indent(@char_index) > @indent && @input[@char_index] != "\n"
      console.log "indent"
      indent = @stream.indent(@char_index)
      while (@stream.indent(@char_index) > @indent)
        buffer += @input[@char_index]
        @char_index++
      if @input[@char_index-1] == "\n"
        @char_index--
        buffer = buffer.substr(0,buffer.length-1)
      source = (line.substr(indent) for line in buffer.split("\n")).join("\n")
      return { type: 'block', token: buffer, source: source }


    while @input[@char_index] in WHITESPACE
      console.log "whitespace"
      @char_index += 1

    return null if @char_index > @input.length

    # match OPERATORS
    if @input[@char_index] in OPERATORS
      while (c = @input[@char_index]) in OPERATORS
        buffer += c
        @char_index += 1
      return { type: "operator", token: buffer}

    # match SYMBOL
    if /([a-zA-Z_])/.test @input[@char_index]
      while (c = @input[@char_index]) and /([a-zA-Z0-9_])/.test c
        buffer += c
        @char_index += 1
      return {type: "symbol", token: buffer}

    # match NUMBER
    if /([0-9])/.test @input[@char_index]
      while (c = @input[@char_index]) and /([0-9]|\.|\,)/.test c
        buffer += c
        @char_index += 1
      if @input[@char_index-1] == ',' # toss back last commas
        buffer = buffer.substr(0,buffer.length-1)
        @char_index -= 1
      return {type: "number", token: buffer, value: parseFloat(buffer.replace(",",""))}

    # match STRINGS
    if @input[@char_index] in ["'",'"']
      boundary = @input[@char_index]
      @char_index += 1
      while (c = @input[@char_index]) != boundary
        buffer += c
        @char_index += 1
        if (c = @input[@char_index]) == "\\" # read chars after \ regardless
          buffer += c
          @char_index += 1
          buffer += c
          @char_index += 1
      if @input[@char_index] == boundary
        @char_index += 1
        return {type: "string", token: boundary+buffer+boundary, value: buffer}
      else
        throw new SyntaxError("Unterminated String")

    # match LINEFEED
    if @input[@char_index] == "\n"
      @char_index += 1
      return {type: 'linefeed', token: "\n"}

    throw new SyntaxError("Unknown token: #{@input[@char_index]}")
