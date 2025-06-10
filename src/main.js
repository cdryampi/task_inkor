import './assets/main.css'
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { setupCalendar, Calendar, DatePicker } from 'v-calendar'
import 'v-calendar/style.css'
import "flowbite";
const app = createApp(App)

// Configurar V-Calendar con idioma español
app.use(setupCalendar, {
  locale: 'es',
  firstDayOfWeek: 2, // Lunes como primer día
  masks: {
    weekdays: 'WWW',
    navMonths: 'MMMM',
    title: 'MMMM YYYY',
    dayPopover: 'WWW, MMM D, YYYY'
  }
})

// Registrar componentes globalmente
app.component('VCalendar', Calendar)
app.component('VDatePicker', DatePicker)

app.use(router)
app.mount('#app')
