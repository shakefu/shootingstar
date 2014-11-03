


if Meteor.isClient
  notificationCollection = new Meteor.Collection null

  notifications.on 'message', (message, time) ->
    notificationCollection.insert
      message: message
      time: time

  Template.server.helpers
    messages: ->
      notificationCollection.find()

    dateString: ->
      new Date this.time
        .toString()

