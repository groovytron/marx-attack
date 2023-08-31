import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default () => {
  return defineConfig({
    plugins: [vue()],
    build: {
      sourcemap: process.env.NODE_ENV === 'development',
    },
    // https://github.com/intlify/vue-i18n-next/issues/789#issuecomment-1138210323
    resolve: {
      alias: [
        {
          find: 'vue-i18n',
          replacement: 'vue-i18n/dist/vue-i18n.cjs.js',
        }
      ]
    }
  });
};
