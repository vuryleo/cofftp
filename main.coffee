FtpClient = require './lib/client'
config = require './config'

client = new FtpClient()
client.connect config.port, config.host, obtain()
client.login config.username, config.password, obtain()
client.ls obtain()
client.cd 'pub', obtain()
client.ls obtain()
client.exit()

