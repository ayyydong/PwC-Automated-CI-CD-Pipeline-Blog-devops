module.exports = {
  env: {
    node: true,
    es2021: true,
  },
  settings: {
    react: {
      version: "detect"
    },
  },
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  overrides: [],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  plugins: ['react', '@typescript-eslint'],
  rules: {
    // suppress errors for missing 'import React' in files
    'react/react-in-jsx-scope': 'off',
    // allow jsx syntax in js/ts files
    'react/jsx-filename-extension': [
      1,
      { extensions: ['.js', '.jsx', 'ts', 'tsx'] },
    ],
  },
}
