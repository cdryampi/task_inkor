import './assets/main.css'
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { setupCalendar, Calendar, DatePicker } from 'v-calendar'
import 'v-calendar/style.css'
import "flowbite";
import 'notivue/notification.css' // Only needed if using built-in <Notification />
import 'notivue/animations.css' // Only needed if using default animations
import { createNotivue } from 'notivue'

const notivue = createNotivue({
  position: 'top-right',
  limit: 4,
  enqueue: true,
  avoidDuplicates: true,
  notifications: {
    global: {
      duration: 5000
    }
  }
})
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
app.use(notivue)

// Registrar componentes globalmente
app.component('VCalendar', Calendar)
app.component('VDatePicker', DatePicker)

app.use(router)
app.mount('#app')
