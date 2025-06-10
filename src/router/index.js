import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/mis-tareas',
      name: 'mis-tareas',
      component: () => import('../views/MisTareasView.vue'),
    },
    {
      path: '/mis-tareas-completadas',
      name: 'mis-tareas-completadas',
      component: () => import('../views/MisTareasCompletadasView.vue'),
    },
    {
      path: '/calendario',
      name: 'calendario',
      component: () => import('../views/CalendarioView.vue'),
    },
    {
      path: '/estadisticas',
      name: 'estadisticas',
      component: () => import('../views/EstadisticasView.vue'),
    },
    {
      path: '/configuracion',
      name: 'configuracion',
      component: () => import('../views/ConfiguracionView.vue'),
    }
  ],
})

export default router
