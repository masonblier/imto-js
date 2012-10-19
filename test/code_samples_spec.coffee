
fs = require 'fs'
path = require 'path'
imto = require('../src')

make_test = (filename) ->
  it filename.replace(".im","").replace("_"," "), ->
    interpreter = new imto.Interpreter()
    lines = (line for line in fs.readFileSync(
      path.join(__dirname, "code_samples/" + filename), 
      "utf8"
    ).split("\n") when not /^[ \t]*$/.test line)
    index = 0
    res = null
    while index < lines.length
      if lines[index].indexOf(">") is 0
        start = index
        while index < lines.length and lines[index].indexOf(">") is 0
          lines[index] = lines[index].substr(1)
          index += 1 
        try
          res = interpreter.eval lines.slice(start,index).join("\n")
        catch ex
          res = ex
      else
        start = index
        while index < lines.length and lines[index].indexOf(">") isnt 0
          index += 1
        lines.slice(start,index).join("\n").should.eql res.toString()

describe 'code samples', ->
  for file in fs.readdirSync path.join(__dirname, "code_samples")
    make_test file