fs = require 'fs'
lineparser = require 'lineparser'
prompt =  require 'prompt'
readline = require 'readline'
logger = require './logger'
FtpClient = require './client'
Table = require 'cli-table'

prompt.message = "[INPUT]".inverse
prompt.delimiter = " > ".green

module.exports = FtpClientShell = () ->
  that = this
  @client = new FtpClient()

  this

FtpClientShell::cd = (r, callback) ->
  @client.cd r[0], callback

FtpClientShell::pwd = (r, callback) ->
  @client.pwd callback


FtpClientShell::help = (r, callback) ->
  callback null,
"cofftp
A Ftp written in CoffeeScript

Client commands:
  connect [host] [port]
  login
  ls
  cd [directory]
  pwd
  upload localFile [remoteFile]
  download remoteFile [localFile]
"

FtpClientShell::shell = () ->
  that = this
  @repl = readline.createInterface
    input: process.stdin
    output: process.stdout
  @repl.setPrompt 'cofftp> '

  @repl.prompt()
  @repl.on 'line', (cmd) ->
    try
      that.exec cmd, obtain result
      console.log result if result
    catch err
      logger.error err.message
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
  @client.ls obtain list
  table = new Table
    head: ['Name', 'Type', 'Last Modify']
  for i in list
    table.push i
  console.log table.toString()

FtpClientShell::connect = (r, callback) ->
  @client.connect r[0] || 'localhost', r[1] || 2121, callback

FtpClientShell::upload = (r, callback) ->
  that = this
  fs.readFile r[0], obtain data
  that.client.put r[1] || r[0], data, callback

FtpClientShell::download = (r, callback) ->
  that = this
  that.client.get r[0], obtain data
  fs.writeFile r[1] || r[0], data, callback

FtpClientShell::disconnect = (r, callback) ->
  that = this
  that.client.exit callback

FtpClientShell::quit = (r, callback) ->
  process.exit()

FtpClientShell::exec = (text, callback) ->
  text = text.split ' '
  if this[text[0]] instanceof Function
    this[text[0]] text[1..text.length - 1], callback
  else
    callback Error "#{text[0]} is not a avaliable command"

