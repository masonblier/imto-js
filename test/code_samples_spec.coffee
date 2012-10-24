
fs = require 'fs'
path = require 'path'
imto = require('../src')

make_test = (expected, actual, description) ->
  it description, ->
    expected.should.eql actual

load_imto_files = (filename) ->
  describe filename.replace(".im","").replace("_"," "), ->
    interpreter = new imto.Interpreter()
    lines = (line for line in fs.readFileSync(
      path.join(__dirname, "code_samples/" + filename), 
      "utf8"
    ).split("\n") when not /^[ \t]*$/.test line)
    index = 0
    test_description = undefined
    actual = undefined
    while index < lines.length
      if lines[index].indexOf(">") is 0
        start = index
        while index < lines.length and lines[index].indexOf("> ") is 0
          lines[index] = lines[index].substr(2)
          index += 1 
        try
          res = interpreter.eval lines.slice(start,index).join("\n")
          actual = if typeof res is "string" then res else JSON.stringify res
        catch ex
          actual = ex.toString()
      else if lines[index].indexOf("#") is 0
        first = lines[index]
        while lines[index].indexOf("#") is 0
          index += 1
        test_description = "#{first.substr(1)}"
      else
        start = index
        while index < lines.length and not (lines[index][0] in [">","#"])
          index += 1
        expected = (for line in lines.slice(start,index) 
          if (value = parseFloat line) and value != NaN
            value
          else
            try 
              JSON.stringify(JSON.parse(line))
            catch e
              line
        ).join("\n")
        make_test expected, actual, test_description

describe 'code samples', ->
  for file in fs.readdirSync path.join(__dirname, "code_samples")
    load_imto_files file