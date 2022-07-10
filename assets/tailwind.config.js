// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  darkMode: 'class',
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  safelist: [
    'bg-green-500',
    'bg-yellow-500',
    'bg-zinc-500'
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
        ],
        mono: [
          'Inconsolata',
          ...defaultTheme.fontFamily.mono,
        ]

      }
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
