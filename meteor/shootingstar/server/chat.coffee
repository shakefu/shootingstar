channels = new Meteor.Stream 'channels'

channels.permissions.read (userId, eventName) -> true
channels.permissions.write (userId, eventName) -> true

Active = new Meteor.Collection 'active'
Active.remove {}

Meteor.publish 'active', -> Active.find()

channels.addFilter (event, args) ->
  subscriptionId = @subscriptionId
  user = args?[0]?.user
  channel = args?[0]?.channel
  if event is '__join'
    member = _sub: subscriptionId, user: user, channel: channel
    active = Active.findOne member
    if not active and (user and channel)
      Active.insert member
      @onDisconnect = ->
        channels.emit channel, "#{user} has disconnected."
        Active.remove _sub: subscriptionId
  else if event is '__part'
    Active.remove _sub: subscriptionId
  return args

