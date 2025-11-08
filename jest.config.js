'use strict';

const config = {
  clearMocks: true,
  restoreMocks: true,
  resetMocks: true,

  testEnvironment: 'jsdom',

  testPathIgnorePatterns: ['config/', 'tests/'],
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1'
  },
  transform: {
    '^.+\\.js$': ['@swc/jest']
  },
  setupFilesAfterEnv: [
    './app/javascript/test/setupJestDomMatchers.js',
    './app/javascript/test/setupExpectEachTestHasAssertions.js'
  ]
};

module.exports = config;
