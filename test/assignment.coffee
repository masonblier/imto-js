redl = require('../')

describe 'interpreter', ->

  interpreter = null

  beforeEach ->
    interpreter = new redl.Interpreter()

  describe 'assignment operations', ->

    it 'should save the variable to the context'#, ->
    #   interpreter.eval('myVar = \'hi\'')
    #   myVar = interpreter.context.get('myVar')
    #   myVar.should.equal 'hi'

    # 