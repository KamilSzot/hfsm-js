module.exports = () => {
  return {
    files: [
      {pattern: 'node_modules/*', instrument: false},
      'hfsm-js.ts'
    ],
    tests: [
      'test.ts'
    ],
    env: {
      type: 'node'
    },
    debug: true
  };
};
