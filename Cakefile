fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

run_proc = (command, args, callback) ->
  child = spawn command, args
  child.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  child.stdout.on 'data', (data) ->
    process.stdout.write data.toString()
  child.on 'exit', (code) ->
    callback?() if code is 0

compile_cs = (callback) ->
  run_proc './node_modules/.bin/coffee', ['-c', '-o', 'lib', 'src'], callback?()

browserify = (callback) ->
  run_proc './node_modules/.bin/browserify', ['-o','public/redl.js','lib/browser.js'], callback?()

build = () ->
  compile_cs browserify

test = () ->
  run_proc './node_modules/.bin/mocha', ['--colors','--reporter','spec']

task 'build', "Build all js files", -> build()
task 'test', "Run all tests", -> test()
