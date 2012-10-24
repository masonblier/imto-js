
fs = require 'fs'
path = require 'path'
imto = require('../src')

make_test = (expected, actual, description) ->
  it description, ->
    expected.should.eql actual

load_imto_files = (filename) ->
  describe filename.replace(".im","").replace("_"," "), ->
    lines = (line for line in fs.readFileSync(
      path.join(__dirname, "code_samples/" + filename), 
      "utf8"
    ).split("\n") when not /^[ \t]*$/.test line)
    index = 0
    test_description = undefined
    actual = undefined
    while index < lines.length
      if lines[index].indexOf("#") is 0
        first = lines[index]
        while lines[index].indexOf("#") is 0
          index += 1
        test_description = "#{first.substr(1)}"

      if lines[index].indexOf("$") is 0
        start = index
        while index < lines.length and lines[index].indexOf("$ ") is 0
          lines[index] = lines[index].substr(2)
          index += 1 
        try
          interpreter = new imto.Interpreter()
          res = interpreter.eval lines.slice(start,index).join("\n")
          actual = res
        catch ex
          actual = ex.toString()

      start = index
      while index < lines.length and not (lines[index][0] in ["$","#"])
        index += 1
      str = lines.slice(start,index).join("\n")
      if str?.length > 0
        expected = 
          try
            if (/^[0-9\.]+$/.test str)
              parseFloat str
            else if JSON.parse(str)
              JSON.parse(str)
            else
              str
          catch e
            str
        make_test expected, actual, test_description
      else
        xit test_description

describe 'code samples', ->
  for file in fs.readdirSync path.join(__dirname, "code_samples")
    load_imto_files file