net = require 'net'
fs = require 'fs'

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
  @_connect port, host, obtain res
  callback()

FtpClient::login = (username, password, callback) ->
  that = this
  that.sendCmd 'USER ' + username, obtain res # TODO handle error
  that.sendCmd 'PASS ' + password, obtain res
  callback()

FtpClient::getPasvSocket = (callback) ->
  @sendCmd 'PASV', obtain res
  addr = getPasvAddr res
  if addr is false
    callback new Error 'PASV: Bad host/port combination'
  socket = net.createConnection addr[1], addr[0]
  callback null, socket

FtpClient::ls = (callback) ->
  @getPasvSocket obtain socket
  callback()

FtpClient::exit = ->
  @socket.end()

getPasvAddr = (text) ->
  pasvreg = /([-\d]+,[-\d]+,[-\d]+,[-\d]+),([-\d]+),([-\d]+)/
  match = pasvreg.exec(text)
  if not match
     false
  else
    [match[1].replace(/,/g, "."), (parseInt(match[2], 10) & 255) * 256 + (parseInt(match[3], 10) & 255)]
