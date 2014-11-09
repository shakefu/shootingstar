###
# Log

This module exposes a fully configured winston logger to the application for
ease of use.

###
winston = require 'winston'

config = require './config'


# When we're running tests, create a dummy logger with no transports and skip
# initializing properly
if config.get('env') is 'test'
  module.exports = new winston.Logger()
  return


# Create a base instance that logs to the console
logger = new winston.Logger()
  .add winston.transports.Console

# If logrotate is enabled, we don't use the default filehandler, and use the
# DailyRotateFile transport instead
if config.get 'logging.logrotate'
  logger.add winston.transports.DailyRotateFile,
    filename: config.get 'logging.filename'
else
  logger.add winston.transports.File,
    filename: config.get 'logging.filename'


module.exports = logger

