FtpClientShell = require './lib/shell'
prompt = require 'prompt'
config = require './config'

shell = new FtpClientShell()
exec = (cmd, context, filename, callback) ->
  #console.log cmd.toString()
  callback()
  #shell.exec cmd, callback

repl.start
  prompt: 'cofftp > '
  input: process.stdin
  output: process.stdout
  eval: exec

