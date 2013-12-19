net = require 'net'
fs = require 'fs'
path = require 'path'
logger = require './logger'

module.exports = FtpServer = () ->
  that = this
  @server = net.createServer (c) ->
    logger.status 'server created'
    that.loggedin = false
    c.write genResponse 220, "cofftp 0.0.0 ready"
    that.localAddress = c.localAddress
    that.root = path.normalize '.'
    that.wd = that.root
    c.on 'end', () ->
      logger.status 'server ended'
    c.on 'data', (data) ->
      logger.command data.toString()
      data = data.toString().toLowerCase().replace('\r\n', '').split ' '
      if that[data[0]] instanceof Function and data[0] not in ['listen', 'genPath']
        that[data[0]] data[1..data.length - 1], obtain code, message
        c.write genResponse code, message
      else
        c.write genResponse 502, "#{data[0]} not implemented."

FtpServer::listen = (part, callback) ->
  @server.listen port, obtain()
  logger.status "listening #{host}:#{port}"
  callback()

FtpServer::user = (r, callback) ->
  @username = r[0]
  callback null, 331, "Username ok, send password."

FtpServer::pass = (r, callback) ->
  if @username is 'user' and r[0] is '12345'
    @loggedin = true
    callback null, 230, "welcome #{@username}."
  else
    callback null, 530, "Authentication failed."

FtpServer::pwd = (r, callback) ->
  that = this
  console.log that.checkLogin.toString()
  that.checkLogin callback, obtain()
  callback null, 257, "#{that.genPath()} is the current directory."

FtpServer::cwd = (r, callback) ->
  that = this
  that.checkLogin callback, obtain()
  that.wd = path.resolve that.wd, r[0]
  if path.relative(that.root, that.wd).slice(0, 2) is '..'
    that.wd = that.root
  callback null, 250, "#{that.genPath()} is the current directory."

FtpServer::type = (r, callback) ->
  that = this
  that.checkLogin callback, obtain()
  switch r[0]
    when 'i' then callback null, 200, "Type set to: Binary."

FtpServer::pasv = (r, callback) ->
  that = this
  that.checkLogin callback, obtain()
  that.passserver = net.createServer (c) ->
    that.passsocket = c
    logger.status 'data server created'
    if that.datatosend
      c.end that.datatosend
      that.datatosend = null
    c.on 'end', () ->
      logger.status 'data server ended'
      that.passsocket = null
      callback null, 226, "Transfer complete."
    c.on 'data', (data) ->
      if that.passcallback instanceof Function
        that.passcallback null, data
      that.passcallback = null
  that.passserver.listen obtain()
  port = that.passserver.address().port
  addr = that.localAddress
  callback null, 227, "Entering passive mode #{encodePassiveSocket addr, port}."

FtpServer::mlsd = (r, callback) ->
  that = this
  that.checkLogin callback, obtain()
  fs.readdir that.wd, obtain files
  res = []
  for name in files
    fs.stat path.join(that.wd, name), obtain stat
    res.push encodeFileStat name, stat
  if that.passsocket
    that.passsocket.end res.join '\r\n'
  else
    that.datatosend = res.join '\r\n'
  callback null, 150, "File status okay. About to open data connection."

FtpServer::stor = (r, callback) ->
  that = this
  that.checkLogin callback, obtain()
  that.passcallback = (err, data) ->
    fs.writeFile r[0], data
  callback null, 150, "File status okay. About to open data connection."

FtpServer::retr = (r, callback) ->
  that = this
  @checkLogin callback, obtain()
  fs.readFile r[0], obtain data
  if that.passsocket
    that.passsocket.end data
  else
    that.datatosend = data
  callback null, 150, "File status okay. About to open data connection."

FtpServer::genPath = () ->
  relative = "/#{path.relative @root, @wd}"

FtpServer::checkLogin = (callback, next) ->
  if not @loggedin
    callback null, 530, "Log in with USER and PASS first."
  else
    next()

encoodeDate = (date) ->
  "#{date.getUTCFullYear()}#{date.getUTCMonth()}#{date.getUTCDate()}#{date.getUTCHours()}#{date.getUTCMinutes()}#{date.getUTCSeconds()}"

encodeFileStat = (name, fstate) ->
  "modify=#{encoodeDate fstate.mtime};perm=;size=#{fstate.size};type=#{if fstate.isDirectory() then 'dir' else 'file'};unique=#{fstate.ino};#{name}"

encodePassiveSocket = (addr, port) ->
  "(#{addr.replace /\./g, ','},#{parseInt(port / 256)},#{port & 255})"

genResponse = (code, message) ->
  "#{code} #{message}\r\n"

