const { rules } = require('eslint-plugin-react')

module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:react/jsx-runtime',
    '@electron-toolkit/eslint-config-ts/recommended',
    '@electron-toolkit/eslint-config-prettier'
  ],
  rules: {
    ...rules,
    '@typescript-eslint/explicit-function-return-type': 'off'
  }
}
