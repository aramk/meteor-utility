# https://github.com/awatson1978/meteor-cookbook/blob/master/cookbook/environment-detection.md

Environment =

  get: (callback) ->
    if Meteor.isServer
      env = process.env.NODE_ENV
      if env?
        env
      else if process.env.ROOT_URL?.indexOf('//localhost:3000') >= 0
        'development'
      else
        'production'
    else
      Promises.serverMethodCall('Environment.get', callback)

if Meteor.isServer

  Meteor.methods
    'Environment.get': -> Environment.get()
