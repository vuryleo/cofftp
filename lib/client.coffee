net = require 'net'
fs = require 'fs'
logger = require './logger'

module.exports = FtpClient = () ->
  that = this
  @socket = net.Socket()
  @pending = []
  @socket.on 'data', (data) ->
    data = data.toString()
    logger.response data
    callback = that.pending[0]
    that.pending = that.pending[1..that.pending.length - 1] || []
    if (callback)
      callback null, data
  this

FtpClient::sendCmd = (cmd, callback) ->
  if cmd.split(' ')[0] isnt 'PASS'
    console.log "Commad: #{cmd}".command
  else
    console.log 'PASS ******'.command
  @pending.push callback
  @socket.write cmd + '\r\n'

FtpClient::connect = (host, port, callback) ->
  @pending.push callback
  @socket.connect port, host
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
  logger.status "Connect to #{addr.host}:#{addr.port}"
  socket = net.connect addr.port, addr.host
  socket.on 'connect', () ->
    logger.status 'Data socket connected'
  socket.on 'end', () ->
    logger.status 'Data socket closed'
  callback null, socket

FtpClient::ls = (callback) ->
  that = this
  that.sendCmd 'TYPE I', obtain res
  that.sendCmd 'MLSD', obtain res
  that.getPasvSocket obtain socket
  socket.on 'data', (data) ->
    callback null, parseMlsdResponse data.toString()
  that.pending.push (err, res) ->
    socket.end()

FtpClient::cd = (directory, callback) ->
  that = this
  that.sendCmd 'CWD ' + directory, obtain res
  callback()

FtpClient::pwd = (callback) ->
  that = this
  that.sendCmd 'PWD', obtain res
  callback()

FtpClient::put = (name, data, callback) ->
  that = this
  that.sendCmd 'TYPE I', obtain res
  that.sendCmd "STOR #{name}", obtain res
  that.getPasvSocket obtain socket
  socket.write data, () ->
    socket.end()
    callback

FtpClient::get = (name, callback) ->
  that = this
  that.sendCmd 'TYPE I', obtain res
  that.sendCmd "RETR #{name}", obtain res
  that.getPasvSocket obtain socket
  socket.on 'data', (data) ->
    callback null, data
  that.pending.push (err, res) ->
    socket.end()

FtpClient::exit = (callback) ->
  that = this
  that.sendCmd 'QUIT', callback
  that.socket.end()

parseMlsdResponse = (text) ->
  listreg = /modify=([^;]*);perm=(.*);size=(.*);type=(.*);unique=(.*);(.*)/
  table = []
  for line in text.split '\r\n'
    match = listreg.exec line
    if line
      if not match
        continue
      else
        table.push [match[6], match[4], match[1]]
  table

parsePasvAddr = (text) ->
  pasvreg = /([-\d]+,[-\d]+,[-\d]+,[-\d]+),([-\d]+),([-\d]+)/
  match = pasvreg.exec text
  if not match
     false
  else
    [match[1].replace(/,/g, "."), (parseInt(match[2], 10) & 255) * 256 + (parseInt(match[3], 10) & 255)]
