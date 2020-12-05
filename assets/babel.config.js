module.exports = {
  env: {
    test: {
      presets: [
        ['@babel/preset-env', {targets: {node: 'current'}}],
        "@babel/preset-react"
      ],
    },
    development: {
      presets: [
        [
          '@babel/preset-env',
          {
            modules: false,
            targets: {
              node: 'current',
            },
          },
        ],
        "@babel/preset-react"
      ],
    },
    production: {
      presets: [
        [
          '@babel/preset-env',
          {
            modules: false,
            targets: {
              node: 'current',
            },
          },
        ],
        "@babel/preset-react"
      ],
    }
  }
};
