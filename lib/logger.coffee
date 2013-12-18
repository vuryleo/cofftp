colors = require 'colors'

theme =
  response: 'green'
  command: 'cyan'
  status: 'yellow'
  error: 'red'
  warning: 'orange'

colors.setTheme theme

module.exports = Logger = () ->

Logger.response = (data) ->
  console.log "Response: #{data}".response

Logger.command = (data) ->
  console.log "Command: #{data}".command

Logger.status = (data) ->
  console.log "Status: #{data}".status

Logger.error = (data) ->
  console.log "Error: #{data}".error
