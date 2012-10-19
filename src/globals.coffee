# Globals

{inspect}    = require 'util'

enableColours = no
unless process.platform is 'win32'
  enableColours = not process.env.NODE_DISABLE_COLORS

global.clc = 
  if enableColours
    require('cli-color')
  else
    green: (a) -> a
    blue:  (a) -> a
    red:   (a) -> a

global.pp = (obj) ->
  console.log("------------");
  console.log(inspect(obj, true, 4, true));
global.p = (node) ->
  process.stdout.write("============\n#{node}\n");

class global.ImtoError extends Error
  constructor: (@message, options) ->
    super(message)
    @tracking = options.tracking if options?.tracking?
  toString: () =>
    if @tracking?
      "{#{@tracking.line},#{@tracking.column}} #{@message}" 
    else
      @message

# sprint node function
sprint = (list, indent = "") ->
  (for node in list
    head = "#{indent}(#{clc.green(node.type)}"
    if node.type is "block"
      "#{head}\n#{sprint(node.parse(),indent+"  ")}\n#{indent})"
    else if node.type is "function"
      "#{head}\n#{sprint([node.body],indent+"  ")}\n#{indent})"
    else if node.type is "execute"
      "#{head} #{clc.blue("#{node.symbol}")}#{if node.params?.length > 0 then "\n#{sprint(node.params,indent+"  ")}\n#{indent}" else ""})" 
    else if node.type is "hash"
      "#{head} #{if node.statements?.length > 0 then "\n#{sprint(node.statements,indent+"  ")}\n#{indent}" else ""})" 
    else if node.type is "operator"
      nodes = [node.left]
      nodes.push node.right if node.right?
      "#{head} #{clc.blue("#{node.operator}")}\n#{sprint(nodes,indent+"  ")}\n#{indent})" 
    else if node.type is "assignment" or node.type is "hash_assignment"
      "#{head} #{clc.blue("#{node.symbol}")}\n#{sprint([node.value],indent+"  ")}\n#{indent})" 
    else if node.type is "literal"
      "#{head} #{clc.red(node.token)})"
    else
      "#{head} '#{node.token}')"
  ).join "\n"

class global.ParseNode
  constructor: (options) ->
    for own p of options
      @[p] = options[p]
  toString: () =>
    sprint [@]
