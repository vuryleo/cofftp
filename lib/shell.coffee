lineparser = require 'lineparser'
prompt =  require 'prompt'
readline = require 'readline'
FtpClient = require './client'

prompt.message = "[INPUT]".inverse
prompt.delimiter = " > ".green

module.exports = FtpClientShell = () ->
  that = this

  @shell = () ->
    that = this
    @repl = readline.createInterface
      input: process.stdin
      output: process.stdout
    @repl.setPrompt 'cofftp> '

    @repl.prompt()
    @repl.on 'line', (cmd) ->
      that.exec cmd, obtain result
      console.log result
      that.repl.prompt()

  @login = (r, callback) ->
    that = this
    that.repl.close()
    prompt.get
      properties:
        username:
          required: true
        password:
          hidden: true
    , obtain user
    callback null, user.username
    that.shell()

  @exec = (text, callback) ->
    text = text.split ' '
    switch text[0]
      when 'login' then @login null, callback

  @client = new FtpClient()
  this


FtpClientShell::ls = (r, callback) ->
  @client.ls callback

FtpClientShell::cd = (r, callback) ->
  @client.cd r.args[0], callback

FtpClientShell::pwd = (r, callback) ->
  @client.pwd callback

FtpClientShell::connect = (r, callback) ->
  @client.connect r.host, r.port, callback


FtpClientShell::help = (r, callback) ->
  #console.log r.help()
  callback r.help()

