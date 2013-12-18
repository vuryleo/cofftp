FtpClientShell = require './lib/shell'
prompt = require 'prompt'
repl = require 'repl'
config = require './config'

repl.ignoreUndefined = true

shell = new FtpClientShell()

shell.shell()
