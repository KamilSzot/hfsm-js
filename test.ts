/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS201: Simplify complex destructure assignments
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import * as chai from 'chai';
chai.should();

import 'mocha'

import {State, Regions} from './hfsm-js';

describe('State machine', function() {
  
  let {output, states} = {} as { output: string[], states:State };

  beforeEach(function() {
    let active:Regions, operational:State;
    output = [];
    const l = output.push.bind(output);
    states = new State({
      _default: 'operational',
      operational: (operational = new State({
        _deepHistory: 'stopped',
        enter() {
          l("> operational");
        },
        exit() {
          l("< operational");
        },
        on: {
          flip() {
            states.go('flipped');
          }
        },
        stopped: new State({
          enter() {
            l("> stopped");
          },
          exit() {
            l("< stopped");
          },
          on: {
            play() {
              operational.go('active', 'running');
            }
          }
        }),
        active: (active = new Regions({
          main: new State({
            _default: 'paused',
            enter() {
              l("> active");
            },
            exit() {
              l("< active");
            },
            running: new State({
              enter() {
                l("> running");
              },
              exit() {
                l("< running");
              },
              on: {
                pause(){
                  active.go('paused');
                }
              }
            }),
            paused: new State({
              enter() {
                l("> paused");
              },
              exit() {
                l("< paused");
              },
              on: {
                play() {
                  active.go('running');
                }
              }
            })
          }),
          light: new State({
              enter() {
                l("> light");
              },
              exit() {
                l("< light");
              }
          })
        }))
      })),
      flipped: new State({
        enter() {
          l('> flipped');
        },
        exit() {
          l('< flipped');
        },
        on: {
          flip() {
            states.go('operational');
          }
        }
      })
    });
    states.go();
  });

  describe('after initial transition', function() {
    it('should start with _default state', () =>
      states._current
        .should.equal(states.substates[states._default])
  );

    it('should call enter() of "stopped" substate and be in it', function() {
      const last = output[output.length - 1];

      last.should.equal('> stopped');
    });

    it('should enter() "playing" and "light" state after receiving "play" message', function() {
      states.trigger('play');
      const beforeLast = output[output.length - 2], last = output[output.length - 1];
      [last, beforeLast].should.contain('> running');
      [last, beforeLast].should.contain('> light');
    });

    it('should exit() "active" state enter() "paused" state after receiving "pause" message', function() {
      states.trigger('play');
      states.trigger('pause');

      const beforeLast = output[output.length - 2], last = output[output.length - 1];
      beforeLast
        .should.equal('< running');

      last
        .should.equal('> paused');
    });

    it('should keep operational substates after flipping twice', function() {
      states.trigger('play');
      states.trigger('flip');
      states.trigger('flip');

      const beforeLast = output[output.length - 2], last = output[output.length - 1];
      beforeLast
        .should.equal('> running');

      last
        .should.equal('> light');
    });
  });
});

// states.trigger 'pause'
// states.trigger 'flip'
// states.trigger 'flip'
