# requirements

Cursor = require "./cursor"

WHITESPACE = [' ', '\t']
OPERATORS = ['=','+','-','*','/','<','>','%','&','(',')','[',']','^',':','?','.']

class SyntaxError extends Error

class CharCursor extends Cursor
  constructor: (@input) ->
    super()
    @input = @input.replace("\r","")
    @length = @input.length
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
  constructor: (input) ->
    super()
    @memo_index = -1
    @memos = []
    @linestart = true
    @indent = 0
    @char_cursor = new CharCursor(input)
    # skip starter newlines
    while @char_cursor.peek()?.char == "\n"
      @char_cursor.next()

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
    cc = @char_cursor

    # skip blank line
    ws = 1
    while cc.peek(ws)?.char in WHITESPACE
      ws += 1
    if ws > 1 and cc.peek(ws)?.char == "\n"
      cc.next(ws)

    # skip double newlines
    while cc.peek()?.char == "\n" and cc.peek(2)?.char == "\n"
      cc.next()
    # skip newlines with indents after them
    while cc.peek()?.char == "\n" and cc.indent(cc.index+1) > @indent
      cc.next()

    tracking_start = cc.peek()

    # match indentation block
    if cc.peek()? and cc.peek().char != "\n" and cc.indent(cc.index) > @indent
      indent = cc.indent(cc.index)
      while cc.index < cc.length and (cc.indent(cc.index) > @indent)
        buffer += cc.next().char
      if cc.prev(0)?.char == "\n"
        cc.back()
        buffer = buffer.substr(0,buffer.length-1)
      source = (line.substr(indent) for line in buffer.split("\n")).join("\n")      
      return { 
        type: 'block', 
        token: buffer, 
        source: source, 
        tracking: { start: tracking_start, end: cc.peek(0) } 
      }

    while cc.peek()?.char in WHITESPACE
      cc.next()
    return null unless cc.index < cc.length
    tracking_start = cc.peek()

    # match bracketted block
    if cc.peek().char in ["{", "[", "("]
      stack = 1
      buffer = cc.next().char
      type = 'block'

      while stack > 0 and cc.index < cc.length
        stack -= 1 if cc.peek().char in ["}","]",")"]  
        stack += 1 if cc.peek().char in ["{", "[", "("]
        buffer += cc.next().char
      throw new SyntaxError("Unbalanced Parenthesis") if stack > 0
      # start parsing out source: 
      source = buffer.substring(1, buffer.length-1)
      # scan past last bracket, skipping whitespace
      lookahead = 1
      while cc.peek(lookahead)?.char in WHITESPACE
        lookahead += 1
      # if -> found, it's a function signature
      if (cc.peek(lookahead)?.char == "-" or "=") and cc.peek(lookahead+1)?.char == ">"
        buffer += (cc.peek(i).char for i in [0..lookahead+1]).join("")
        cc.index = cc.index+lookahead+1
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
        tracking: { start: tracking_start, end: cc.peek(0) } 
      }

    # match OPERATORS
    if cc.peek().char in OPERATORS
      while cc.peek()?.char in OPERATORS
        buffer += cc.next().char      
      return { 
        type: "operator", token: buffer, 
        tracking: { start: tracking_start, end: cc.peek(0) } 
      }

    # match SYMBOL
    if /([a-zA-Z_@])/.test cc.peek().char
      buffer = cc.next().char
      while cc.peek()? and /([a-zA-Z0-9_])/.test cc.peek().char
        buffer += cc.next().char      
      return {
        type: "symbol", token: buffer,
        tracking: { start: tracking_start, end: cc.peek(0) } 
      }

    # match NUMBER
    if /([0-9])/.test cc.peek().char
      while cc.peek()? and /([0-9]|\.|\,)/.test cc.peek().char
        buffer += cc.next().char
      if cc.prev(0)?.char == ',' # toss back last commas
        buffer = buffer.substr(0,buffer.length-1)      
      return {
        type: "number", token: buffer, value: parseFloat(buffer.replace(",","")),
        tracking: { start: tracking_start, end: cc.peek(0) } 
      }

    # match STRINGS
    if cc.peek().char in ["'",'"']
      boundary = cc.next().char
      while cc.peek()? and cc.peek()?.char != boundary
        buffer += cc.next().char
        if (cc.peek()?.char) == "\\" # read chars after \ regardless
          buffer += cc.next().char
          buffer += cc.next().char
      if cc.next()?.char == boundary
        return {
          type: "string", token: "#{boundary}#{buffer}#{boundary}", value: buffer,
          tracking: { start: tracking_start, end: cc.peek(0) } }
      else
        throw new SyntaxError("Unterminated String")

    # match LINEFEED
    if cc.peek().char == "\n"
      cc.next()
      return {
        type: 'linefeed', token: "\n",
        tracking: { start: tracking_start, end: cc.peek(0) } 
      }

    throw new SyntaxError("Unknown token: #{cc.next()}")
