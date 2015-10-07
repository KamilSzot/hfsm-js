util = require 'util'


l = console.log.bind console

class Regions
  constructor: (@all) ->
  _exit: (args...) ->
    @all.forEach (states) ->
      states._exit(args...)
  _enter: (args...) ->
    @all.forEach (states) ->
      states._enter(args...)
  trigger: (args...) ->
    @all.forEach (states) ->
      states.trigger(args...)
  to: (args...) ->
    @all.forEach (states) ->
      states.to(args...)

class States
  constructor: (conf) ->
    for k, v of conf
      @[k] = v
  _exit: (keep, deep) ->
    if @state
      keep ||= @_deepHistory || @_history
      deep ||= @_deepHistory
      @state._exit(keep && deep, deep)
      if @state.exit
        @state.exit()
      if keep
        @_historyState = @state
      delete @state
  _enter: (nextState, nextSubstates...) ->
    if @enter
      @enter()
    @state = @[nextState] ? @_historyState ? @[@_default ? @_history ? @_deepHistory]
    if !@state
      throw "Invalid state"
    delete @_historyState
    if nextSubstates[0] || @state._default || @state._historyState || @state._history || @state._deepHistory
      @state._enter(nextSubstates...)
  to: (states...) ->
    @_exit()
    @_enter(states...)
  on: ->
  trigger: (e) ->
    @on(e, @to.bind(@))
    if @state
      @state.trigger(e)


states = new States
  _default: 'operational'
  operational: new States
    _deepHistory: 'stopped'
    enter: ->
      l "> operational"
    exit: ->
      l "< operational"
    on: (e) ->
      if e == 'flip'
        states.to('flipped')
    stopped: new States
      enter: ->
        l "> stopped"
      exit: ->
        l "< stopped"
      on: (e) ->
        if e == 'play'
          states.operational.to('active', 'running')
    active: active = new States
      _default: 'paused'
      enter: ->
        l "> active"
      exit: ->
        l "< active"
      running: new States
        enter: ->
          l "> running"
        exit: ->
          l "< running"
        on: (e) ->
          if e == 'pause'
            active.to('paused')

      # running: new Regions
      #   motor: new States
      #     enter: ->
      #       l "> running"
      #     exit: ->
      #       l "< running"
      #     on: (e) ->
      #       if e == 'pause'
      #         active.to('paused')
      #   light: new States
      #     enter: ->
      #       l "> light"
      #     exit: ->
      #       l "< light"
      paused: new States
        enter: ->
          l "> paused"
        exit: ->
          l "< paused"
        on: (e) ->
          if e == 'play'
            active.to('running')
  flipped: new States
    enter: ->
      l '> flipped'
    exit: ->
      l '< flipped'
    on: (e) ->
      if e == 'flip'
        states.to('operational')



states.to(states._default)
states.trigger 'play'
states.trigger 'pause'
states.trigger 'flip'
states.trigger 'flip'
