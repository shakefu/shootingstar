###
# Config

Loads server configurations from JSON files and makes them available via the
convict API.

###
path = require 'path'

convict = require 'convict'

conf = convict
  env:
    doc: "the application environment"
    format: ['production', 'staging', 'test', 'development']
    default: 'development'
    env: 'NODE_ENV'
    arg: 'node-env'

  logging:
    filename:
      doc: "Log filename to use"
      format: String
      default: './shootingstar.log'
      env: 'LOG_FILE'
    logrotate:
      doc: "Toggle log rotation"
      format: Boolean
      default: false
      env: 'LOG_ROTATE'

  server:
    host:
      doc: "IP to bind to"
      format: 'ipaddress'
      default: '127.0.0.1'
      env: 'HOST'
    port:
      doc: "Port to listen on"
      format: 'port'
      default: '9399'
      env: 'PORT'


do ->
  # Load NODE_ENV based configuration
  env = conf.get 'env'
  file = path.resolve __dirname + "./../config/#{env}.json"
  try
    conf.loadFile file
  catch err
    if err.message.slice(0, 6) != "ENOENT"
      throw err
    console.log "Skipped config, not found: #{file}"

  # Load localconfig if it exists
  file = path.resolve __dirname + "./../localconfig.json"
  try
    conf.loadFile file
  catch err
    if err.message.slice(0, 6) != "ENOENT"
      throw err
    # Too much logging here
    # console.log "Skipping localconfig.json"


conf.validate()


module.exports = conf

