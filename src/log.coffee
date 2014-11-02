###
# Log

This module exposes a fully configured winston logger to the application for
ease of use.

###
winston = require 'winston'

config = require './config'


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

