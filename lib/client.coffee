net = require 'net'
fs = require 'fs'

logger = (text) ->
  console.log 'Status: ' + text

module.exports = FtpClient = (config) ->
  that = this
  @socket = net.Socket()
  @pending = []
  @socket.on 'data', (data) ->
    data = data.toString()
    console.log 'Reponse: ' + data
    callback = that.pending[0]
    that.pending = that.pending[1:-1] || []
    if (callback)
      callback null, data
  this

FtpClient::sendCmd = (cmd, callback) ->
  console.log 'Commad: ' + cmd
  @pending.push callback
  @socket.write cmd + '\r\n'

FtpClient::_connect = (port, host, callback) ->
  @pending.push callback
  @socket.connect port, host

FtpClient::connect = (port, host, callback) ->
  that = this
  that._connect port, host, obtain res
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

FtpClient::exit = ->
  that = this
  @sendCmd 'QUIT', obtain()
  that.socket.end()

parseListResponse = (text) ->
  console.log 'Name\tType\tModify'
  listreg = /modify=([^;]*);perm=(.*);size=(.*);type=(.*);unique=(.*);(.*)/
  for line in text.split '\r\n'
    match = listreg.exec line
    if not match
      false
    else
      console.log match[6] + '\t' + match[4] + '\t' + match[1]

parsePasvAddr = (text) ->
  pasvreg = /([-\d]+,[-\d]+,[-\d]+,[-\d]+),([-\d]+),([-\d]+)/
  match = pasvreg.exec text
  if not match
     false
  else
    [match[1].replace(/,/g, "."), (parseInt(match[2], 10) & 255) * 256 + (parseInt(match[3], 10) & 255)]
