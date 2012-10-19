# Globals

{inspect}    = require 'util'

global.pp = (obj) ->
  console.log("------------");
  console.log(inspect(obj, true, 4, true));
global.p = (node) ->
  process.stdout.write("============\n#{node}\n");

global.ImtoError = class ImtoError extends Error
  constructor: (@message, options) ->
    super(message)
    @tracking = options.tracking if options?.tracking?
  toString: () =>
    if @tracking?
      "{#{@tracking.line},#{@tracking.column}} #{@message}" 
    else
      @message