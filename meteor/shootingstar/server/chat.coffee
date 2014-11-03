channels = new Meteor.Stream 'channels'

channels.permissions.read (userId, eventName) -> true

