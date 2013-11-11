Tracks = new Meteor.Collection 'tracks'
buttons = new Meteor.Collection 'buttons'

if Meteor.isClient
  Template.button_grid.osc_button_grid = (x,y) ->
    console.log [x,y].join ','

  Template.osc_button.events
    'click div': (e) ->
      b = buttons.findOne {_id: @_id}
      Meteor.call 'send_osc', '/live/track/info', @button_num
      buttons.update {_id: @_id}, {$set:{pressed:if b.pressed=='' then 'pressed' else ''}}
  
  Template.button_grid.buttons = ->
  	buttons.find {}

  Template.mixer.events
    'click #button_play': -> Meteor.call 'send_osc', '/live/play'
    'click #button_stop': -> Meteor.call 'send_osc', '/live/stop'
    'dragstart .slider-button': (e) ->
      e.target.yOffset = e.target.style.getPropertyValue('top') - e.clientY
    'change input.volume-fader': (e) ->
      Meteor.call 'send_osc', '/live/volume', e.target.dataset['trackNum'], parseInt(e.target.value)/100.0
      console.log e

  Template.mixer.tracks = ->
    Tracks.find {}

if Meteor.isServer
  oscClient = null
  oscServer = null
  Meteor.startup ->
    osc = Npm.require 'node-osc'
    oscClient = new osc.Client('127.0.0.1', 9000);

    oscClient.send('/live/name/track');

    oscServer = new osc.Server(9001, '127.0.0.1');
    oscServer.on 'message', (msg, rinfo) ->
      console.log msg, rinfo

      processMsg = (msg) ->
        handlers =
          '#bundle': (msg) ->
            console.log 'processing bundle!'
            processMsg bundledMsg for bundledMsg in msg[2..msg.count] if msg[0] is '#bundle'
          '/live/name/track': (msg) ->
            console.log 'track named ' + msg[2]
            Tracks.upsert { num: msg[1] }, { num: msg[1], name: msg[2] }
        if handlers.hasOwnProperty msg[0] then handlers[msg[0]] msg

      Fiber = Npm.require 'fibers'
      Fiber(processMsg).run msg


    console.log 'OSC listening on :9001...'

    buttons.remove {}

    buttons.insert {button_num: i, pressed:'', text: ''} for i in [1..8]

  Meteor.methods
    send_osc: ->
      console.log 'sending OSC message' + arguments
      oscClient.send.apply oscClient, arguments
