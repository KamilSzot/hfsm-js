/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const l = console.log.bind(console);

export class Regions {
  all:{[name:string]:State|Regions}
  constructor(all:{[name:string]:State|Regions}) {
    this.all = all;
  }
  _exit(keep:boolean = false, deep:boolean = false) {
    for (let region in this.all) {
      const state = this.all[region];
      state._exit(keep, deep);
    }
  }
  _exitDescend(keep:boolean, deep:boolean) {
      for (let region in this.all) {
        const state = this.all[region];
        state._exitDescend(keep, deep);
      }
  }
  _switchToState(nextState:string, ...nextSubstates:string[]) {
      for (let region in this.all) {
        const state = this.all[region];
        state._switchToState(nextState, ...nextSubstates);
      }
  }
  _enterState(nextState?:string, ...nextSubstates:string[]) {
      for (let region in this.all) {
        const state = this.all[region];
        // if (state[nextState]) {
        //   state._enterState(nextState, ...nextSubstates);
        // } else {
        //   // don't pass rest of the path to regions that don't have action of target name
        //   state._enterState();
        // }
      }
  }
  trigger(e:string, ...payload:any[]):void {
      for (let region in this.all) {
        const state = this.all[region];
        state.trigger(e, ...payload);
      }
  }
  go(nextState:string, ...nextSubstates:string[]) {
    let supported = false;
    for (let region in this.all) {
      const state = this.all[region];
      // if (state[nextState]) {
      //   // ignore regions without the target state
      //   state.go(nextState, ...Array.from(nextSubstates));
      //   supported = true;
      // }
    }
    if (!supported) {
      throw `Invalid state ${nextState}`;
    }
  }
}

type EventHandler = () => void


export class State {
  on:{[name:string]:() => void};
  _current:State|Regions;
  _historyState:State|Regions;

  _default:string;
  _history:string;
  _deepHistory:string;

  exit?: () => void;
  enter?: () => void;
  substates: {[name:string]:State|Regions}

  constructor(conf:{
    on?: {[eventName: string]:EventHandler}, 
    enter?: EventHandler, 
    exit?: EventHandler,
    _default?: string,
    _history?: string,
    _deepHistory?: string,
  } & {[name:string]:any }) {
    var { enter, exit, on, _default, _history, _deepHistory, ...substates } = conf;
    this.enter = enter;
    this.exit = exit;
    this.on = on || {};
    this._default = _default;
    this._history = _history;
    this._deepHistory = _deepHistory;
    this.substates = substates;
  }
  _exit(keep:boolean = false, deep:boolean = false):void {
    if (this._current) {
      if (!keep) { keep = (this._deepHistory != null) || (this._history != null); }
      if (!deep) { deep = (this._deepHistory != null); }
      this._current._exitDescend(keep, deep);
      if (keep) { // TO CHECK: Should use orginal keep value?
        this._historyState = this._current;
      }
      delete this._current;
    }
  }
  _exitDescend(keep:boolean, deep:boolean):void {
    this._exit(keep && deep, deep);
    if (this.exit) {
      this.exit();
    }
  }
  _switchToState(nextState:string, ...nextSubstates:string[]):void {
    if (nextState && !this.substates[nextState]) {
      throw `Invalid state ${nextState}`;
    }
    
    this._current = this.substates[nextState] || this._historyState || this.substates[this._default || this._history || this._deepHistory];
    delete this._historyState;
    if(this._current) {
      const [state, ...substates] = nextSubstates || [] as string[];
  //    console.error(nextSubstates || [] as string[]);
      this._current._enterState(state, ...substates);
    }
  }
  _enterState(nextState?:string, ...nextSubstates:string[]):void {
      if (this.enter) {
        this.enter();
      }
      this._switchToState(nextState, ...nextSubstates);
    }

  go(nextState?:string, ...nextSubstates:string[]) {
    this._exit();
    this._switchToState(nextState, ...nextSubstates);
  }
  trigger(e:string, ...payload:any[]):void {
    if (this.on[e]) {
      this.on[e].call(this, ...payload);
    }
    if (this._current) {
      this._current.trigger(e, ...payload);
    }
  }
}


