/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        'monad-purple': {
          DEFAULT: '#7e49f2',
          dark: '#6437d4',
          light: '#a07ff5',
        },
        dark: {
          900: '#121212',
          800: '#1e1e1e',
          700: '#2d2d2d',
          600: '#3d3d3d',
          500: '#4d4d4d',
          400: '#6e6e6e',
          300: '#909090',
          200: '#b1b1b1',
          100: '#d1d1d1',
        }
      },
    },
  },
  plugins: [],
};