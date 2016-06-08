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
  _switchToState: (nextState, nextSubstates...) ->
    for region, state of @all
      state._switchToState(nextState, nextSubstates...)
  _enterState: (args...) ->
    for region, state of @all
      if state[args[0]]
        state._enterState(args...)
      else
        # don't pass rest of the path to regions that don't have action of target name
        state._enterState()
  add: (state) ->
    @all.push state
  trigger: (args...) ->
    for region, state of @all
      state.trigger(args...)
  go: (nextState, nextSubstates...) ->
    supported = false
    for region, state of @all
      if state[nextState]
        # ignore regions without the target state
        state.go(nextState, nextSubstates...)
        supported = true
    if !supported
      throw "Invalid state "+nextState

class State
  constructor: (conf) ->
    @on = {}
    for k, v of conf
      @[k] = v
  _exit: (keep, deep) ->
    if @_current
      keep ||= @_deepHistory? || @_history?
      deep ||= @_deepHistory?
      @_current._exitDescend(keep, deep)
      if keep
        @_historyState = @_current
      delete @_current
  _exitDescend: (keep, deep)->
    @_exit(keep && deep, deep)
    if @exit
      @exit()
  _switchToState: (nextState, nextSubstates...) ->
    if nextState && !@[nextState]
      throw "Invalid state "+nextState
    @_current = @[nextState] ? @_historyState ? @[@_default ? @_history ? @_deepHistory]
    delete @_historyState
    @_current._enterState(nextSubstates...)
  _enterState: (subState, nextSubstates...) ->
      if @enter
        @enter((intstead...) -> [subState, nextSubstates...] = intstead)
      if subState || @_historyState || @_default || @_history || @_deepHistory
        @_switchToState(subState, nextSubstates...)

  go: (nextState, nextSubstates...) ->
    @_exit()
    @_switchToState(nextState, nextSubstates...)
  trigger: (e, payload...) ->
    if @on[e]
      @on[e].call(@, payload...)
    if @_current
      @_current.trigger(e, payload...)

module.exports = {State, Regions}
