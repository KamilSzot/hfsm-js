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
  _enter: (nextState, nextSubstates...) ->
    for region, state of @all
      state._enter(nextState, nextSubstates...)
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
  _enter: (nextState, nextSubstates...) ->
    if nextState && !@[nextState]
      throw "Invalid state "+nextState
    @_current = @[nextState] ? @_historyState ? @[@_default ? @_history ? @_deepHistory]
    delete @_historyState
    @_current._enterDescend(nextSubstates...)
  _enterDescend: (nextState, nextSubstates...) ->
      if @enter
        @enter()
      if nextState || @_default || @_historyState || @_history || @_deepHistory
        @_enter(nextState, nextSubstates...)

  go: (nextState, nextSubstates...) ->
    @_exit()
    @_enter(nextState, nextSubstates...)
  trigger: (e, payload...) ->
    if @on[e]
      @on[e](@go.bind(@), payload...)
    if @_current
      @_current.trigger(e, payload...)

module.exports = {State, Regions}
