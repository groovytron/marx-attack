import { createApp } from 'vue';
import './style.css';
import App from './App.vue';
import { createI18n } from 'vue-i18n';

// import translations
import fr from "./assets/i18n/fr.json";
import de from "./assets/i18n/de.json";
import en from "./assets/i18n/en.json";

const app = createApp(App);

const i18n = createI18n({
  warnHtmlInMessage: 'off',
  fallbackLocale: "en",
  messages: {
    fr,
    de,
    en,
  },
})

app.use(i18n)

app.mount('#app')
