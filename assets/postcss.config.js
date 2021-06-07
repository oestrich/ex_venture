module.exports = {
  syntax: 'postcss-scss',
  plugins: [
    require('tailwindcss')('./tailwind.config.js'),
    require('postcss-advanced-variables'),
    require('postcss-nested'),
    require('autoprefixer'),
  ],
}
