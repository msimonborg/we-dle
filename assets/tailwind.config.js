// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: [
          'Lato',
          ...defaultTheme.fontFamily.sans,
        ],
        serif: [
          '"Bree Serif"',
          ...defaultTheme.fontFamily.serif,
        ]
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
