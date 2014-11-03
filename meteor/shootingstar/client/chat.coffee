channels = new Meteor.Stream 'channels'
messages = new Meteor.Collection null


Meteor.subscribe 'active'
Active = new Meteor.Collection 'active'


currentUser = null
userName = -> Meteor.user()?.profile?.name


getMessage = (msg, user) ->
  messages.insert message: msg, user: user, date: new Date()


addMessage = (msg, user) ->
  channel = currentChannel()
  channels.emit channel, msg, user if channel
  messages.insert message: msg, user: user, date: new Date()


currentChannel = (channel) ->
  Session.set 'channel', channel if channel?
  Session.get 'channel'


leaveChannel = (channel) ->
  return unless channel? and currentUser?
  channels.removeListener channel, getMessage
  addMessage "#{currentUser} has left #{channel}."
  channels.emit '__part', user: currentUser, channel: channel
  Session.set 'channel'


Tracker.autorun ->
  if userName() then currentUser = userName()
  else leaveChannel currentChannel()


setChannel = (e) ->
  old_channel = currentChannel()
  channel = $(e.currentTarget).val()
  return unless channel

  if channel and old_channel
    if (channel != old_channel) then leaveChannel old_channel
    else return

  channels.on channel, getMessage
  currentChannel channel
  addMessage "#{userName()} joined #{channel}."
  channels.emit '__join', user: currentUser, channel: channel
  $('#message').focus()


Template.chat.helpers
  channel: -> currentChannel()
  messages: -> messages.find {}, sort: date: -1
  rooms: ->
    _rooms = {}
    Active.find().forEach (active) ->
      return unless active?.channel?
      _rooms[active.channel] ?= 0
      _rooms[active.channel] += 1
    rooms = []
    for room of _rooms
      rooms.push name: room, count: _rooms[room]
    rooms
  users: -> Active.find {channel: currentChannel()}, sort: user: 1


Template.chat.events
  'keyup #channel': (e) ->
    return unless e.keyCode is 13
    return addMessage "Please sign in." unless userName()
    setChannel e

  'blur #channel': (e) ->
    return addMessage "Please sign in." unless userName()
    setChannel e

  'keyup #message': (e) ->
    return unless e.keyCode is 13
    return addMessage "Please sign in." unless userName()
    return addMessage "Join a channel." unless currentChannel()
    input = $(e.currentTarget)
    addMessage input.val(), userName()
    input.val ''


