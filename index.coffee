util = require 'util'


l = console.log.bind console

class Regions
  constructor: (@all) ->
  _exit: (args...) ->
    for region, state of @all
      state._exit(args...)
  _exitDescend: (args...) ->
    for region, state of @all
      state._exitDescend(args...)
  _enter: (next, args...) ->
    for region, state of @all
      state._enter(next, args...)
  _enterDescend: (args...) ->
    for region, state of @all
      if state[args[0]]
        state._enterDescend(args...)
      else
        # don't pass rest of the path to regions that don't have action of target name
        state._enterDescend()
  trigger: (args...) ->
    for region, state of @all
      state.trigger(args...)
  to: (args...) ->
    for region, state of @all
      if state[args[0]]
        # ignore regions without the target state
        state.to(args...)

class State
  constructor: (conf) ->
    for k, v of conf
      @[k] = v
  _exit: (keep, deep) ->
    if @_current
      keep ||= @_deepHistory || @_history
      deep ||= @_deepHistory
      @_current._exit(keep && deep, deep)
      @_current._exitDescend()
      if keep
        @_historyState = @_current
      delete @_current
  _exitDescend: ->
    if @exit
      @exit()
  _enter: (nextState, nextSubstates...) ->
    if nextState && !@[nextState]
      throw "Invalid state "+nextState
    @_current = @[nextState] ? @_historyState ? @[@_default ? @_history ? @_deepHistory]
    delete @_historyState
    @_current._enterDescend(nextSubstates...)
  _enterDescend: (nextSubstates...) ->
      if @enter
        @enter()
      if nextSubstates[0] || @_default || @_historyState || @_history || @_deepHistory
        @_enter(nextSubstates...)

  to: (states...) ->
    @_exit()
    @_enter(states...)
  on: ->
  trigger: (e) ->
    @on(e, @to.bind(@))
    if @_current
      @_current.trigger(e)


states = new State
  _default: 'operational'
  operational: operational = new State
    _deepHistory: 'stopped'
    enter: ->
      l "> operational"
    exit: ->
      l "< operational"
    on: (e) ->
      if e == 'flip'
        states.to('flipped')
    stopped: new State
      enter: ->
        l "> stopped"
      exit: ->
        l "< stopped"
      on: (e) ->
        if e == 'play'
          operational.to('active', 'running')
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
          on: (e) ->
            if e == 'pause'
              active.to('paused')
        paused: new State
          enter: ->
            l "> paused"
          exit: ->
            l "< paused"
          on: (e) ->
            if e == 'play'
              active.to('running')
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
    on: (e) ->
      if e == 'flip'
        states.to('operational')



states.to()
states.trigger 'play'
states.trigger 'pause'
states.trigger 'flip'
states.trigger 'flip'
