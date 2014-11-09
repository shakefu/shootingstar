chai = require 'chai'
events = require 'events'

server = require '../lib/server'

should = chai.should()
expect = chai.expect


# MockSock is just a hilarious class name. It made me giggle.
class MockSock extends events.EventEmitter
  # Stub out write which will be replaced by individual tests
  write: ->
  end: ->


# So this is a bit wonky 'cause it's checking for specific strings being
# written to the socket... not really i18n friendly, for example, but will
# work for checking against the project spec.
describe "ChatSession", ->
  # Helper for making a new mock socket and tying it a session
  mock = ->
    socket = new MockSock()
    session = new server.ChatSession socket
    return [socket, session]

  it "should give a login prompt on initializing", (done) ->
    socket = new MockSock()
    socket.write = (data) ->
      # Look for the login string, since two things are sent on init
      if data is "Login name?\n"
        done()

    new server.ChatSession socket

  it "should emit a login event on logging in", (done) ->
    [socket, session] = mock()
    session.on 'login', (name, callback) ->
      expect(callback).to.be.a 'function'
      expect(name).to.equal "Name"
      done()
    socket.emit 'data', "Name"

  describe "input handling", ->
    user = "Name"
    room = "Room"
    # Create a mock session for testing commands
    [socket, session] = mock()
    # Helper so I don't have to type socket.emit 'data' a zillion times
    input = (data) -> socket.emit 'data', data

    before (done) ->
      # Make the command session be logged in so we can test commands without
      # initializing a new session for each one
      socket.write = (data) -> done() if data is "Welcome #{user}!\n"
      # Approve the login
      session.on 'login', (name, callback) -> callback null, name
      # Send our chosen user name
      input user

    afterEach ->
      # Ensure we clean up the socket and session instances for each test
      session.removeAllListeners()
      socket.write = ->

    it "should be give an error message for gibberish", (done) ->
      socket.write = (data) ->
        data.should.equal "Huh? Try /help.\n"
        done()
      input "gibberish"

    it "should be give an error message for gibberish commands", (done) ->
      socket.write = (data) ->
        data.should.have.string "Unknown command"
        done()
      input "/gibberish"

    it "should give you some help", (done) ->
      socket.write = (data) ->
        data.should.have.string "Available commands"
        done()
      input "/help"

    it "should tell you you're not in a room if you try to /leave", (done) ->
      socket.write = (data) ->
        data.should.have.string "You're not in a room"
        done()
      input "/leave"

    it "should error at you if you try /who outside a room", (done) ->
      socket.write = (data) ->
        data.should.have.string "Try /help"
        done()
      input "/who"

    it "should emit a listChannels event when trying /rooms", (done) ->
      session.on 'listChannels', -> done()
      input "/rooms"

    it "should prompt you for help if you use /join without a room", (done) ->
      socket.write = (data) ->
        data.should.have.string "Try /help"
        done()
      input "/join"

    # This test has to come after since it changes the state to be in a room
    it "should emit a join event when successfully joining", (done) ->
      session.on 'join', (channel, name) ->
        expect(name).to.equal user
        expect(channel).to.equal room
        done()
      input "/join #{room}"

    it "should emit a channel event when just talking in a room", (done) ->
      session.on 'channel', (channel, msg) ->
        expect(channel).to.equal room
        expect(msg).to.have.string "#{user}: Hello"
        done()
      input "Hello"

    it "should emit a listChannel event for /who", (done) ->
      session.on 'listChannel', -> done()
      input "/who"

    # And this has to follow the join since the user must be in a room
    it "should emit a part event when leaving a room", (done) ->
      session.on 'part', (channel, name) ->
        expect(name).to.equal user
        expect(channel).to.equal room
        done()
      input "/leave"

    # And this comes last since it closes stuff done
    it "should emit a quit event on /quit", (done) ->
      session.on 'quit', (name) ->
        expect(name).to.equal user
        done()
      input "/quit"


describe "ChatServer", ->
  user = "Name"
  room = "Room"
  chat_server = new server.ChatServer()
  socket = new MockSock()
  session = chat_server.connect socket

  # Saving keystrokes, maybe
  input = (data) -> socket.emit 'data', data

  before (done) ->
    # Make the command session be logged in so we can test commands without
    # initializing a new session for each one
    socket.write = (data) -> done() if data is "Welcome #{user}!\n"
    # Send our chosen user name
    input user

  it "should emit a channel event in response to a join", (done) ->
    callback = (channel, msg) ->
      expect(channel).to.equal channel
      expect(msg).to.have.string "joined chat"
      # Cleaning up
      chat_server.removeListener 'channel', callback
      done()
    chat_server.on 'channel', callback
    input "/join #{room}"

  it "should hit the callback with a channels object", (done) ->
    session.emit 'listChannels', (channels) ->
      chans = {}
      chans[room] = [user]
      expect(channels).to.eql chans
      done()

  it "should hit the callback with a list of users", (done) ->
    session.emit 'listChannel', room, (users) ->
      expect(users).to.eql [user]
      done()

  it "should disallow the same name for login events", (done) ->
    session.emit 'login', user, (err, name) ->
      expect(err).to.not.be.null
      expect(name).to.equal user
      done()

  it "should emit a channel event in response to a part", (done) ->
    callback = (channel, msg) ->
      expect(channel).to.equal room
      expect(msg).to.have.string "left"
      chat_server.removeListener 'channel', callback
      done()
    chat_server.on 'channel', callback
    input "/leave"

