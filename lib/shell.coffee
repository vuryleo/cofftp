lineparser = require 'lineparser'
read = require 'read'
FtpClient = require './client'



module.exports = FtpClientShell = () ->
  that = this
  @client = new FtpClient()
  console.log @client.senCmd
  @meta =
    program: 'cofftp'
    name: 'Coffeescript Ftp Client'
    version: '0.0.0'
    subcommands: ['ls', 'cd', 'pwd', 'login', 'connect', 'help']
    usages: [
      ['ls', null, null, 'list current directory', that.ls]
      ['cd', null, ['dest'], 'change current directory', that.cd]
      ['pwd', null, null, 'display current directory', that.pwd]
      ['login', null, null, 'login', that.login]
      ['connect', null, ['host', 'port'], 'connect to ftp server', that.connect]
      ['help', null, null, 'display help', that.help]
      [null, null, null, 'display help', that.help]
    ]
  @parser = lineparser.init @meta
  this

FtpClientShell::exec = (text, callback) ->
  @parser.parse text.split ' '
  callback()

FtpClientShell::ls = (r) ->
  @client.ls obtain()

FtpClientShell::cd = (r) ->
  @client.cd r.args[0], obtain()

FtpClientShell::pwd = (r) ->
  @client.pwd obtain()

FtpClientShell::login = (r) ->
  read
    prompt: 'Username: ', obtain username
  read
    prompt: 'Password: '
    slient: true
  , obtain password
  console.log username, password

FtpClientShell::help = (r) ->
  console.log r.help()

