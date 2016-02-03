chai = require 'chai'
chai.should()

CoffeeScript = require 'coffee-script'

describe 'State machine', ->
  {State, Regions} = require './hfsm-js'
  {output, states} = {}

  beforeEach ->
    output = []
    l = output.push.bind(output)
    states = new State
      _default: 'operational'
      operational: operational = new State
        _deepHistory: 'stopped'
        enter: ->
          l "> operational"
        exit: ->
          l "< operational"
        on:
          flip: ->
            states.go('flipped')
        stopped: new State
          enter: ->
            l "> stopped"
          exit: ->
            l "< stopped"
          on:
            play: ->
              operational.go('active', 'running')
        active: active = new Regions
          main: new State
            _default: 'paused'
            enter: ->
              l "> active"
            exit: ->
              l "< active"
            running: new State
              enter: ->
                l "> running"
              exit: ->
                l "< running"
              on:
                pause: (go)->
                  active.go('paused')
            paused: new State
              enter: ->
                l "> paused"
              exit: ->
                l "< paused"
              on:
                play: ->
                  active.go('running')
          light: new State
            enter: ->
              l "> light"
            exit: ->
              l "< light"
      flipped: new State
        enter: ->
          l '> flipped'
        exit: ->
          l '< flipped'
        on:
          flip: ->
            states.go('operational')
    states.go()

  describe 'after initial transition', ->
    it 'should start with _default state', ->
      states._current
        .should.equal states[states._default]

    it 'should call enter() of "stopped" substate and be in it', ->
      [..., last] = output

      last.should.equal '> stopped'

    it 'should enter() "playing" and "light" state after receiving "play" message', ->
      states.trigger 'play'
      [..., beforeLast, last] = output
      [last, beforeLast].should.contain '> running'
      [last, beforeLast].should.contain '> light'

    it 'should exit() "active" state enter() "paused" state after receiving "pause" message', ->
      states.trigger 'play'
      states.trigger 'pause'

      [..., beforeLast, last] = output
      beforeLast
        .should.equal '< running'

      last
        .should.equal '> paused'

# states.trigger 'pause'
# states.trigger 'flip'
# states.trigger 'flip'
