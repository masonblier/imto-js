# context

class Context
  constructor: () ->
    @symbol_table = {}

  set: (symbol, value) =>
    @symbol_table[symbol] = value
  get: (symbol) =>
    @symbol_table[symbol]

module.exports = Context
