// Generated by CoffeeScript 1.9.3
(function() {
  var Regions, State, active, l, operational, states, util,
    slice = [].slice;

  util = require('util');

  l = console.log.bind(console);

  Regions = (function() {
    function Regions(all) {
      this.all = all;
    }

    Regions.prototype._exit = function() {
      var args, ref, region, results, state;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      ref = this.all;
      results = [];
      for (region in ref) {
        state = ref[region];
        results.push(state._exit.apply(state, args));
      }
      return results;
    };

    Regions.prototype._exitDescend = function() {
      var args, ref, region, results, state;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      ref = this.all;
      results = [];
      for (region in ref) {
        state = ref[region];
        results.push(state._exitDescend.apply(state, args));
      }
      return results;
    };

    Regions.prototype._enter = function() {
      var args, next, ref, region, results, state;
      next = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      ref = this.all;
      results = [];
      for (region in ref) {
        state = ref[region];
        results.push(state._enter.apply(state, [next].concat(slice.call(args))));
      }
      return results;
    };

    Regions.prototype._enterDescend = function() {
      var args, ref, region, results, state;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      ref = this.all;
      results = [];
      for (region in ref) {
        state = ref[region];
        if (state[args[0]]) {
          results.push(state._enterDescend.apply(state, args));
        } else {
          results.push(state._enterDescend());
        }
      }
      return results;
    };

    Regions.prototype.trigger = function() {
      var args, ref, region, results, state;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      ref = this.all;
      results = [];
      for (region in ref) {
        state = ref[region];
        results.push(state.trigger.apply(state, args));
      }
      return results;
    };

    Regions.prototype.to = function() {
      var args, ref, region, results, state;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      ref = this.all;
      results = [];
      for (region in ref) {
        state = ref[region];
        if (state[args[0]]) {
          results.push(state.to.apply(state, args));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    return Regions;

  })();

  State = (function() {
    function State(conf) {
      var k, v;
      for (k in conf) {
        v = conf[k];
        this[k] = v;
      }
    }

    State.prototype._exit = function(keep, deep) {
      if (this._current) {
        keep || (keep = this._deepHistory || this._history);
        deep || (deep = this._deepHistory);
        this._current._exit(keep && deep, deep);
        this._current._exitDescend();
        if (keep) {
          this._historyState = this._current;
        }
        return delete this._current;
      }
    };

    State.prototype._exitDescend = function() {
      if (this.exit) {
        return this.exit();
      }
    };

    State.prototype._enter = function() {
      var nextState, nextSubstates, ref, ref1, ref2, ref3, ref4;
      nextState = arguments[0], nextSubstates = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (nextState && !this[nextState]) {
        throw "Invalid state " + nextState;
      }
      this._current = (ref = (ref1 = this[nextState]) != null ? ref1 : this._historyState) != null ? ref : this[(ref2 = (ref3 = this._default) != null ? ref3 : this._history) != null ? ref2 : this._deepHistory];
      delete this._historyState;
      return (ref4 = this._current)._enterDescend.apply(ref4, nextSubstates);
    };

    State.prototype._enterDescend = function() {
      var nextSubstates;
      nextSubstates = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (this.enter) {
        this.enter();
      }
      if (nextSubstates[0] || this._default || this._historyState || this._history || this._deepHistory) {
        return this._enter.apply(this, nextSubstates);
      }
    };

    State.prototype.to = function() {
      var states;
      states = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      this._exit();
      return this._enter.apply(this, states);
    };

    State.prototype.on = function() {};

    State.prototype.trigger = function(e) {
      this.on(e, this.to.bind(this));
      if (this._current) {
        return this._current.trigger(e);
      }
    };

    return State;

  })();

  states = new State({
    _default: 'operational',
    operational: operational = new State({
      _deepHistory: 'stopped',
      enter: function() {
        return l("> operational");
      },
      exit: function() {
        return l("< operational");
      },
      on: function(e) {
        if (e === 'flip') {
          return states.to('flipped');
        }
      },
      stopped: new State({
        enter: function() {
          return l("> stopped");
        },
        exit: function() {
          return l("< stopped");
        },
        on: function(e) {
          if (e === 'play') {
            return operational.to('active', 'running');
          }
        }
      }),
      active: active = new Regions({
        main: new State({
          _default: 'paused',
          enter: function() {
            return l("> active");
          },
          exit: function() {
            return l("< active");
          },
          running: new State({
            enter: function() {
              return l("> running");
            },
            exit: function() {
              return l("< running");
            },
            on: function(e) {
              if (e === 'pause') {
                return active.to('paused');
              }
            }
          }),
          paused: new State({
            enter: function() {
              return l("> paused");
            },
            exit: function() {
              return l("< paused");
            },
            on: function(e) {
              if (e === 'play') {
                return active.to('running');
              }
            }
          })
        }),
        light: new State({
          enter: function() {
            return l("> light");
          },
          exit: function() {
            return l("< light");
          }
        })
      })
    }),
    flipped: new State({
      enter: function() {
        return l('> flipped');
      },
      exit: function() {
        return l('< flipped');
      },
      on: function(e) {
        if (e === 'flip') {
          return states.to('operational');
        }
      }
    })
  });

  states.to();

  states.trigger('play');

  states.trigger('pause');

  states.trigger('flip');

  states.trigger('flip');

}).call(this);
