# context

class SymbolTable
  constructor: () ->
    @symbol_table = {}

  set: (symbol, value) =>
    @symbol_table[symbol] = value
  get: (symbol) =>
    @symbol_table[symbol]

  toJSON: () =>
    @symbol_table

class Context
  constructor: () ->
    @public = new SymbolTable
    @private = new SymbolTable

  toJSON: () =>
    @public.toJSON()


module.exports = Context
