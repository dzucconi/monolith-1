Router  = require 'routers/router'
config  = require 'config/config'

module.exports =
  __name__: ->
    'monolith_' + Math.random().toString(36).substr 2, 9

  log: (name, payload) ->
    console.log payload
    @channels.status.trigger "client-#{name}",
      client: @name
      data: payload

  setupMonitoring: ->
    @name = @__name__()

    @pusher = new Pusher env.PUSHER_KEY,
      authEndpoint: env.PUSHER_AUTH_ENDPOINT
      auth: params: client_id: @name

    @channels =
      command: @pusher.subscribe 'command'
      status: @pusher.subscribe "private-status_#{@name}"
      presence: @pusher.subscribe 'presence-status'

    @channels.command.bind 'restart', (name) =>
      if (name is @name) or (name is 'all')
        window.location.reload()

  authenticate: (options = {}) ->
    _sync = Backbone.sync
    Backbone.sync = (method, model, options) ->
      options.beforeSend = (xhr) ->
        xhr.setRequestHeader 'X-XAPP-TOKEN', env.XAPP_TOKEN
      _sync.apply this, arguments
    options.success()

  initialize: ->
    @authenticate
      success: =>
        @router = new Router
        Backbone.history.start()
        if env.PUSHER_KEY and env.PUSHER_AUTH_ENDPOINT
          @setupMonitoring()
