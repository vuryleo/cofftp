lineparser = require 'lineparser'
prompt =  require 'prompt'
readline = require 'readline'
FtpClient = require './client'

prompt.message = "[INPUT]".inverse
prompt.delimiter = " > ".green

module.exports = FtpClientShell = () ->
  that = this
  @client = new FtpClient()

  this

FtpClientShell::cd = (r, callback) ->
  @client.cd r.args[0], callback

FtpClientShell::pwd = (r, callback) ->
  @client.pwd callback


FtpClientShell::help = (r, callback) ->
  #console.log r.help()
  callback r.help()

FtpClientShell::shell = () ->
  that = this
  @repl = readline.createInterface
    input: process.stdin
    output: process.stdout
  @repl.setPrompt 'cofftp> '

  @repl.prompt()
  @repl.on 'line', (cmd) ->
    that.exec cmd, obtain result
    console.log result if result
    that.repl.prompt()

FtpClientShell::login = (r, callback) ->
  that = this
  that.repl.close()
  prompt.get
    properties:
      username:
        required: true
      password:
        hidden: true
  , obtain user
  that.client.login user.username, user.password, callback
  that.shell()

FtpClientShell::ls = (r, callback) ->
  @client.ls callback

FtpClientShell::connect = (r, callback) ->
  @client.connect r[0], r[1], callback

FtpClientShell::exec = (text, callback) ->
  text = text.split ' '
  this[text[0]] text[1..text.length - 1], callback
