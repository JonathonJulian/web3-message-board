import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import { resolve } from 'path';
import adapter from '@sveltejs/adapter-static';

/** @type {import('@sveltejs/kit').Config} */
export default {
  // Consult https://svelte.dev/docs#compile-time-svelte-preprocess
  // for more information about preprocessors
  preprocess: vitePreprocess(),

  kit: {
    adapter: adapter({
      // Static adapter options
      pages: 'dist',
      assets: 'dist',
      fallback: 'index.html',
      precompress: false,
    }),
    alias: {
      $lib: resolve('./src/lib')
    }
  }
};