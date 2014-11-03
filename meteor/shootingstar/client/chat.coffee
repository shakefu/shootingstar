channels = new Meteor.Stream 'channels'
messages = new Meteor.Collection null


Template.chat.helpers
  messages: ->
    messages.find()

