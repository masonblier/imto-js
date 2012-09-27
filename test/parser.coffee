redl = require('../')

parse = (str) ->
  new redl.Interpreter().parse(str)

describe 'parser', ->

  it 'parenclosure', ->
    parse(" ( 2) ")[0].type.should == 'literal'

  it 'block', ->
    list = parse("this\n  is_a \"block\"\nout")
    list[0].type.should.eql 'symbol'
    list[1].type.should.eql 'block'
    list[1].tree[0].type.should.eql 'symbol'
    list[1].tree[1].type.should.eql 'literal'
    list[2].type.should.eql 'symbol'

  it "function", ->
    parse("()->3")[0].type.should.eql 'function'

  it 'property_assignment', ->
    parse("p: 7")[0].type.should.eql 'property_assignment'

  it 'local_assignment', ->
    parse("a = 7")[0].type.should.eql 'assignment'
