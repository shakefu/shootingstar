notifications = new Meteor.Stream 'server-notifications'

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

if Meteor.isServer
  notifications.permissions.read (userId, eventName) -> true

  setInterval (->
    notifications.emit 'message', "Server Generated Message", Date.now()
  ), 1000

