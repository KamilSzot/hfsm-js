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
  go: (args...) ->
    for region, state of @all
      if state[args[0]]
        # ignore regions without the target state
        state.go(args...)

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

  go: (states...) ->
    @_exit()
    @_enter(states...)
  on: ->
  trigger: (e) ->
    @on(e, @go.bind(@))
    if @_current
      @_current.trigger(e)

module.exports = {State, Regions}
