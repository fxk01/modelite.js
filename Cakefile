# Cakefile for sublime

{unlinkSync, writeFileSync} = require "fs"
{version} = require "./package.json"
{spawn} = require "child_process"
{minify} = require "uglify-js"

task "sbuild", "compile source", ->
  process.stdout.write "Compiling..."
  coffee = spawn "coffee", [
    "-c"
    "-b"
    "-o", ".", "./modelite.coffee"
  ]
  coffee.stdout.pipe process.stdout
  coffee.stderr.pipe process.stderr
  coffee.on "exit", (status) ->
    return if status isnt 0
    console.log "OK!"
    process.stdout.write "Compressing..."
    message = "/*! modelite.js v#{version} | (c) 2015, Kan Kung-Yip. | MIT */"
    try
      {code} = minify "./modelite.js"
      writeFileSync "./modelite.min.js", "#{message}\n#{code}"
      unlinkSync "./modelite.js"
    catch err
      console.err err
    console.log "OK!"
    console.log "No error!"


# EOF
