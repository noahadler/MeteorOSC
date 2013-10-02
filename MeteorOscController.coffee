buttons = new Meteor.Collection 'buttons'

if Meteor.isClient
  Template.hello.osc_button_grid = (x,y) ->
    console.log [x,y].join ','

  Template.osc_button.events
    'click div': (e) ->
      b = buttons.findOne {_id: @_id}
      Meteor.call 'send_osc', '/button', @button_num
      buttons.update {_id: @_id}, {$set:{pressed:if b.pressed=='' then 'pressed' else ''}}

  Template.hello.buttons = ->
  	buttons.find {}

if Meteor.isServer
  oscClient = null
  Meteor.startup ->
    osc = Meteor.require 'node-osc'
    oscClient = new osc.Client('127.0.0.1', 3334);

    oscClient.send('/status', 'someone connected');

    buttons.remove {}
    buttons.insert {button_num: i, pressed:'', text: ''} for i in [1..32]

  Meteor.methods
    send_osc: ->
      console.log 'sending OSC message'
      oscClient.send.apply oscClient, arguments
