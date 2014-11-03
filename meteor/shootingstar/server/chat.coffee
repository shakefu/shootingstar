notifications = new Meteor.Stream 'server-notifications'


notifications.permissions.read (userId, eventName) -> true

setInterval (->
  notifications.emit 'message', "Server Generated Message", Date.now()
), 1000

