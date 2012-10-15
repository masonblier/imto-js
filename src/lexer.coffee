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
      acc += 1 if acc < @input.length
    if acc != @input.length
      throw new Error("Tracking went wrong #{acc}, #{@input.length}")

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
    while line < @line_ends.length and index > @line_ends[line]
      line++
    indent = if @indents[line]? then @indents[line] else 0
    if indent is 0
      indent++ while @lines[line][indent] in WHITESPACE
    indent

#
# Lexer
#

module.exports = class Lexer extends Cursor

  # export Lexer.CharCursor
  @CharCursor: CharCursor

  # constructor
  constructor: (@input) ->
    super()
    @char_index = 0
    @memo_index = -1
    @memos = []
    @linestart = true
    @indent = 0
    @char_cursor = new CharCursor(@input)

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
    buffer = ''
    tracking_start = @char_cursor.at(@char_index)

    # match indentation block
    if @char_cursor.indent(@char_index) > @indent && @input[@char_index] != "\n"
      indent = @char_cursor.indent(@char_index)
      while @char_index < @input.length and (@char_cursor.indent(@char_index) > @indent)
        buffer += @input[@char_index]
        @char_index++
      if @input[@char_index-1] == "\n"
        @char_index--
        buffer = buffer.substr(0,buffer.length-1)
      source = (line.substr(indent) for line in buffer.split("\n")).join("\n")
      return { 
        type: 'block', 
        token: buffer, 
        source: source, 
        tracking: { start: tracking_start, end: @char_cursor.at(@char_index-1) } 
      }

    while @input[@char_index] in WHITESPACE
      @char_index += 1
    return null if @char_index >= @input.length
    tracking_start = @char_cursor.at(@char_index)

    # match bracketted block
    if @input[@char_index] in ["{", "[", "("]

      stack = 1
      buffer = @input[@char_index]
      @char_index += 1
      type = 'block'

      while stack > 0 and @char_index < @input.length
        stack -= 1 if @input[@char_index] in ["}","]",")"]  
        stack += 1 if @input[@char_index] in ["{", "[", "("]
        buffer += @input[@char_index]
        @char_index += 1
      throw new SyntaxError("Unbalanced Parenthesis") if stack > 0
      # start parsing out source: 
      source = buffer.substring(1, buffer.length-1)
      # scan past last bracket, skipping whitespace
      lookahead = 0
      while @input[@char_index+lookahead] in WHITESPACE
        lookahead += 1
      # if -> found, it's a function signature
      if @input[@char_index+lookahead] == "-" and @input[@char_index+lookahead+1] == ">"
        buffer += @input.substr(@char_index, lookahead+2)
        @char_index = @char_index+lookahead+2
        type = 'function'
      # 1) trim whitespace
      ws = 0
      while source[ws] in WHITESPACE
        ws += 1
      source = source.substring(ws)
      # 2) if newline, check indent and format if indented
      if source[0] == "\n"
        source = source.substring(1)
        indent = 0
        while source[indent] in WHITESPACE
          indent += 1
        source = (line.substr(indent) for line in source.split("\n")).join("\n")
      return { 
        type: type, 
        token: buffer, 
        source: source, 
        tracking: { start: tracking_start, end: @char_cursor.at(@char_index-1) } 
      }

    # match OPERATORS
    if @input[@char_index] in OPERATORS
      while (c = @input[@char_index]) in OPERATORS
        buffer += c
        @char_index += 1
      return { 
        type: "operator", token: buffer, 
        tracking: { start: tracking_start, end: @char_cursor.at(@char_index-1) } 
      }

    # match SYMBOL
    if /([a-zA-Z_@])/.test @input[@char_index]
      c = @input[@char_index]
      loop
        buffer += c
        @char_index += 1
        break unless (c = @input[@char_index]) and /([a-zA-Z0-9_])/.test c
      return {
        type: "symbol", token: buffer,
        tracking: { start: tracking_start, end: @char_cursor.at(@char_index-1) } 
      }

    # match NUMBER
    if /([0-9])/.test @input[@char_index]
      while (c = @input[@char_index]) and /([0-9]|\.|\,)/.test c
        buffer += c
        @char_index += 1
      if @input[@char_index-1] == ',' # toss back last commas
        buffer = buffer.substr(0,buffer.length-1)
        @char_index -= 1
      return {
        type: "number", token: buffer, value: parseFloat(buffer.replace(",","")),
        tracking: { start: tracking_start, end: @char_cursor.at(@char_index-1) } 
      }

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
        return {
          type: "string", token: boundary+buffer+boundary, value: buffer,
          tracking: { start: tracking_start, end: @char_cursor.at(@char_index-1) } }
      else
        throw new SyntaxError("Unterminated String")

    # match LINEFEED
    if @input[@char_index] == "\n"
      @char_index += 1
      return {
        type: 'linefeed', token: "\n",
        tracking: { start: tracking_start, end: @char_cursor.at(@char_index-1) } 
      }

    throw new SyntaxError("Unknown token: #{@input[@char_index]}")
