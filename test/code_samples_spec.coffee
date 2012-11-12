
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
    
    while index < lines.length
      test_description = undefined
      actual = undefined
      pending = false
      interpreter = new imto.Interpreter()

      if lines[index].indexOf("#") is 0 and lines[index].indexOf("#=>") isnt 0
        first = lines[index]
        first = first.substr(1) if pending = (first.substr(0,2) is "#-")
        while lines[index].indexOf("#") is 0
          index += 1
        test_description = "#{first.substr(1).trim()}"

      if lines[index].indexOf("#") isnt 0
        start = index
        while index < lines.length and lines[index].indexOf("#") isnt 0
          lines[index] = lines[index]
          index += 1 
        try
          res = interpreter.eval lines.slice(start,index).join("\n")
          actual = res
        catch ex
          actual = ex.toString()

      start = index
      while index < lines.length and lines[index].indexOf("#=>") is 0
        index += 1
      str = (line.substr(3) for line in lines.slice(start,index)).join("\n")
      if !pending and str?.length > 0
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
      else if test_description
        xit test_description

describe 'code samples', ->
  for file in fs.readdirSync path.join(__dirname, "code_samples")
    load_imto_files file