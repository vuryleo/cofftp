net = require 'net'
fs = require 'fs'
colors = require 'colors'
Table = require 'cli-table'

colors.setTheme
  response: 'green'
  command: 'cyan'
  status: 'yellow'

logger = (text) ->
  console.log ('Status: ' + text).status

module.exports = FtpClient = () ->
  that = this
  @socket = net.Socket()
  @pending = []
  @socket.on 'data', (data) ->
    data = data.toString()
    console.log ('Reponse: ' + data).response
    callback = that.pending[0]
    that.pending = that.pending[1:-1] || []
    if (callback)
      callback null, data
  this

FtpClient::sendCmd = (cmd, callback) ->
  console.log ('Commad: ' + cmd).command
  @pending.push callback
  @socket.write cmd + '\r\n'

FtpClient::_connect = (host, port, callback) ->
  @pending.push callback
  @socket.connect port, host

FtpClient::connect = (host, port, callback) ->
  that = this
  that._connect host, port, obtain res
  callback()

FtpClient::login = (username, password, callback) ->
  that = this
  that.sendCmd 'USER ' + username, obtain res # TODO handle error
  that.sendCmd 'PASS ' + password, obtain res
  callback()

FtpClient::getPasvSocket = (callback) ->
  @sendCmd 'PASV', obtain res
  addr = parsePasvAddr res
  if addr is false
    callback new Error 'PASV: Bad host/port combination'
  addr =
    host: addr[0]
    port: addr[1]
  socket = net.connect addr.port, addr.host
  callback null, socket

FtpClient::ls = (callback) ->
  that = this
  that.sendCmd 'TYPE I', obtain res
  that.getPasvSocket obtain socket
  socket.on 'connect', () ->
    logger 'Data socket connected'
  socket.on 'data', (data) ->
    parseListResponse data.toString()
  socket.on 'end', () ->
    logger 'Data socket closed'
  that.sendCmd 'MLSD', obtain res
  that.pending.push (err, res) ->
    socket.end()
    callback()

FtpClient::cd = (directory, callback) ->
  that = this
  that.sendCmd 'CWD ' + directory, obtain res
  callback()

FtpClient::pwd = (callback) ->
  that = this
  that.sendCmd 'PWD', obtain res
  callback()

FtpClient::exit = ->
  that = this
  @sendCmd 'QUIT', obtain()
  that.socket.end()

parseListResponse = (text) ->
  listreg = /modify=([^;]*);perm=(.*);size=(.*);type=(.*);unique=(.*);(.*)/
  table = new Table
    head: ['Name', 'Type', 'Last Modify']
    colWidths:  [20, 5, 20]
  for line in text.split '\r\n'
    match = listreg.exec line
    if not match
      false
    else
      table.push [match[6], match[4], match[1]]
  console.log table.toString()

parsePasvAddr = (text) ->
  pasvreg = /([-\d]+,[-\d]+,[-\d]+,[-\d]+),([-\d]+),([-\d]+)/
  match = pasvreg.exec text
  if not match
     false
  else
    [match[1].replace(/,/g, "."), (parseInt(match[2], 10) & 255) * 256 + (parseInt(match[3], 10) & 255)]
