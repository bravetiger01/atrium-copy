module.exports = {
  env: {
    es2021: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2022,
  },
  extends: ["eslint:recommended"],
  rules: {
    "indent": ["error", 2],
    "quotes": ["error", "double", { "allowTemplateLiterals": true }],
    "max-len": "off",
    "require-jsdoc": "off",
    "object-curly-spacing": ["error", "always"],
    "comma-dangle": ["error", "always-multiline"],
    "operator-linebreak": "off",
  },
};
