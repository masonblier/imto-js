
path = require('path')

middleware = (express) ->
  express.static(path.join(__dirname, '/../public'))

module.exports = middleware
