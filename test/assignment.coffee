redl = require('../')

describe 'interpreter', ->

  interpreter = null

  before ->
    interpreter = new redl.Interpreter()

  describe 'assignment operations', ->

    it 'should save the variable to the context'


