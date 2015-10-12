module.exports = () => {
  return {
    files: [
      {pattern: 'node_modules/*', instrument: false},
      'hfsm-js.coffee'
    ],
    tests: [
      'test.coffee'
    ],
    env: {
      type: 'node'
    },
    debug: true
  };
};
