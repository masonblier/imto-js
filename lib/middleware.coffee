

middleware = (express) ->
  express.static(__dirname+'../public')

module.exports = middleware
