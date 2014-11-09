###
# Server

This module contains the base server, starts the server, and imports the
required modules to handle the server nicely.

###
net = require 'net'
EventEmitter = require('events').EventEmitter

_ = require 'underscore'

log = require './log'
config = require './config'


###
# ChatSession

A wrapper around `net.Socket` for handling an individual client session.

@param {net.Socket} socket - A socket for reading and writing
###
class ChatSession extends EventEmitter
  constructor: (@socket) ->
    # The user's name
    @name = null
    # The user's current channel...
    @channel = null

    # Set the current handler to get a login
    @handler = @loginHandler

    @send "Welcome to the XYZ chat server!"
    @loginHandler()

    # Set up the event listeners for the socket
    @socket.on 'data', @receive
    @socket.on 'end', @onEnd
    @socket.on 'error', @onEnd
    @socket.on 'close', @onEnd
    

  # Write data to this session's socket, appending a newline.
  send: (data) -> @socket.write data + '\n' unless @dead

  # Callback for when data is written to this session's socket
  receive: (data) => @handler? data.toString().trim()

  ###
  Bind an event emitter to this session's event listeners.

  @param {EventEmitter} emitter - An event emitter
  ###
  bind: (emitter) ->
    emitter.on 'channel', @onChannel

  ###
  Handle entered commands (starting with a /) or all input when a user is not
  in a channel

  @param {String} data - User input string
  ###
  commandHandler: (data) =>
    return @error() unless data[0] is '/'

    data = data[1..]
    data = data.split ' '
    cmd = data[0]
    args = data[1..]

    if not @serverCommands[cmd]
      return @error "Unknown command: #{cmd}"

    @serverCommands[cmd].call @, args

  ###
  Handle input when a user is active in a channel

  @param {String} data - User input string
  ###
  channelHandler: (data) =>
    # If it starts with a slash, it's not a chat and we pass to commandHandler
    return @commandHandler data unless data[0] isnt '/'
    @emit 'channel', @channel, "#{@name}: #{data}"

  ###
  Handle channel broadcast events

  @param {String} channel - Channel name receiving message
  @param {String} message - Broadcast message
  ###
  onChannel: (channel, message) =>
    # We're filtering channels here, because otherwise we'd have to set up each
    # channel as its own event emitter, which is doable but more complex.
    return unless @channel is channel
    @send message

  ###
  Valid server commands

  This is a mapping for server command names to their methods.
  ###
  serverCommands:
    # Shows help
    # /help
    help: (args) ->
      @send """
        Available commands:
          /join <room>  Join a chat room
          /leave        Leave your current chat room
          /quit         Disconnect from the server
          /rooms        List all available rooms
          /who [room]   List current users in [room] or your current room
        """

    # Joins a chat room
    # /join <room>
    join: (args) ->
      return @error "Join which room?" unless args.length is 1

      # We only take one argument, the channel name
      channel = args[0]

      # If we're already in a channel, we leave it
      if @channel
        @part()

      # And we announce that we're joining the new channel
      @emit 'join', channel, @name
      # Make this session handle channel talk
      @channel = channel
      @handler = @channelHandler
      # And finally tell the user
      @send "entering room: #{channel}"
      @emit 'listChannel', channel, @listUsers

    # Leave the current channel
    # /leave
    leave: (args) ->
      return @error() if args.length
      return @error "You're not in a room." unless @channel
      @part()

    # Quit the server
    # /quit
    quit: (args) ->
      if @channel
        @part()
      @emit 'quit', @name
      @send "BYE"
      # On the next tick we close the socket and delete the session so it
      # doesn't terminate before sending our goodbye message
      process.nextTick =>
        @socket.end()
        # We might actually want to unbind all the event listeners for this
        # object first, but I'm fairly certain node.js will clean this up for
        # me... probably
        delete @

    # List available rooms
    # /rooms
    rooms: (args) ->
      return @error() if args.length
      @emit 'listChannels', @listChannels

    # List all current users
    # /who [room]
    who: (args) ->
      return @error() if args.length > 1 or (not @channel and args.length is 0)
      channel = if args.length is 1 then args[0] else @channel
      @emit 'listChannel', channel, @listUsers

  # Make the user leave their current channel
  part: ->
    return unless @channel
    # Tell the world we've left
    @emit 'part', @channel, @name
    @channel = null
    # Listen to server commands only
    @handler = @commandHandler

  # Send default error message
  error: (msg) ->
    msg += '\n' unless not msg?
    msg ?= "Huh? "
    @send "#{msg}Try /help."

  ###
  Login phase handler for data received

  This will emit a login event or prompt for a name.

  @param {String} data - Data received from the client
  ###
  loginHandler: (data) ->
    return @emit 'login', data, @onLogin if data
    @send "Login name?"

  ###
  Callback for a login attempt

  If `err` is `null` then the attempt was successful and this method will
  switch the user's state to logged in and listening to server commands.

  @param {String} err - Error message for login attempt
  @param {String} name - Name given for attempt
  ###
  onLogin: (err, name) =>
    if err
      @send err
      @send "Login name?"
      return

    @name = name
    @handler = @commandHandler
    @send "Welcome #{name}!"

  ###
  Callback for listing users in a channel

  @param {Array} users - Array of user names
  ###
  listUsers: (users) =>
    for user in users
      if user is @name
        user += " (you)"
      @send " * #{user}"
    @send "end of list."

  ###
  Callback for listing all channels
  
  The `channel` Object should be structured where each key is a channel name,
  and each value an array of string user names.

  Example:

    `{channel1: ['user1', 'user2'], channel2: ['user3']}`

  @param {Object} channels - All channels and users
  ###
  listChannels: (channels) =>
    # Iterate over all the channels, and list those with users
    out = ''
    for name of channels
      chan = channels[name]
      if chan.length is 0
        continue
      out += "\n * #{name} (#{chan.length})"
    # Handle the case where theres no rooms to list
    if not out
      @send "No active rooms. You should create one with /join!"
    else
      @send "Active rooms are:" + out
      @send "end of list."

  ###
  Handler for anything going wrong with the user's socket or it being closed
  ###
  onEnd: () =>
    @dead = true
    @part() if @channel
    if @name
      @emit 'quit', @name
      log.info "User #{@name} has disconnected"
    else
      log.info "#{@socket.remoteAddress} has disconnected"
    process.nextTick => delete @

# Export for testing
exports.ChatSession = ChatSession



###
# ChatServer

This is intended to be used with net.Server for creating socket listeners that
handle chat commands, as well as other events.
###
class ChatServer extends EventEmitter
  constructor: ->
    # Create the server state object
    @state =
      channels: {}
      users: []

  ###
  Connection callback for net.Server

  @param {net.Socket} socket - Socket instance
  ###
  connect: (socket) =>
    log.info "New connection from #{socket.remoteAddress}"

    # Create a new session
    session = new ChatSession socket

    # XXX Jake: Why use event listeners here instead of direct calls from the
    # session to the server? Well, no good reason other than I wanted to play
    # with EventEmitters and I wanted to try to make a super loosely coupled
    # architecture, for entertainment.

    # And bind its listeners to this server
    session.bind @

    # Finally bind this server's listeners to the session
    @bind session

    # Just returning the session for introspection purposes
    session

  ###
  Bind an event emitter to this server's listeners.

  @param {EventEmitter} emitter - An event emitter
  ###
  bind: (emitter) ->
    emitter.on 'login', @onLogin
    emitter.on 'join', @onJoin
    emitter.on 'part', @onPart
    emitter.on 'channel', @onChannel
    emitter.on 'listChannel', @onListChannel
    emitter.on 'listChannels', @onListChannels
    emitter.on 'quit', @onQuit

  ###
  Handler for a user declaring their name.

  @param {String} name - User name declared
  @param {Function} callback - Called with `(err, name` with results of login
  ###
  onLogin: (name, callback) =>
    if _.contains @state.users, name
      return callback "Sorry, name taken.", name

    log.info "New user #{name}"
    @state.users.push name
    callback null, name

  ###
  Handler for a user wanting to join a channel

  @param {String} channel - Channel name to join
  @param {String} name - User name joining
  ###
  onJoin: (channel, name) =>
    chans = @state.channels
    chans[channel] ?= []
    chans[channel].push name
    # Just to make sure we don't end up with dupes
    chans[channel] = _.uniq chans[channel]
    @emit 'channel', channel, "new user joined chat: #{name}"
    log.info "#{name} joined #{channel}"

  ###
  Handler for when a user leaves a channel

  @param {String} channel - Channel name to leave
  @param {String} name - User name leaving
  ###
  onPart: (channel, name) =>
    chans = @state.channels
    return unless chans[channel]?
    chans[channel] = _.without chans[channel], name
    @emit 'channel', channel, "user has left chat: #{name}"
    log.info "#{name} left #{channel}"

  ###
  Handler for a channel message

  @param {String} channel - Channel receiving the message
  @param {String} msg - Message to broadcast
  ###
  onChannel: (channel, msg) =>
    log.info "#[#{channel}] #{msg}"
    # We just rebroadcast the message
    @emit 'channel', channel, msg

  # Handler for getting a list of users in a channel
  onListChannel: (channel, callback) => callback @state.channels[channel] ? []

  # Handler for getting a list of all channels
  onListChannels: (callback) => callback @state.channels

  ###
  Handler for a user quitting or disconnecting

  @param {String} name - User name that quit
  ###
  onQuit: (name) =>
    return unless name?
    # Clean up user names
    @state.users = _.without @state.users, name
    # Clean up all the channels
    chans = @state.channels
    for chan of chans
      chans[chan] = _.without chans[chan], name
      if chans[chan].length is 0
        delete chans[chan]

# Export the ChatServer class
exports.ChatServer = ChatServer

# Create our server instance
chat_server = new ChatServer()

# Create the server with connection callback
server = net.createServer chat_server.connect

# Make the server listen on the specified host and port
host = config.get 'server.host'
port = config.get 'server.port'
server.listen port, host, ->
  log.info "Listening on #{host}:#{port}"


