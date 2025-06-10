<template>
  <nav class="bg-gradient-to-r from-primary-50 to-primary-100 border-primary-200 shadow-sm">
    <div class="max-w-screen-xl flex flex-wrap items-center justify-between mx-auto p-4">
      <!-- Logo y título -->
      <router-link to="/" class="flex items-center space-x-3 rtl:space-x-reverse">
          <img src="/logo-inkor.svg" class="h-8" alt="Inkor Logo" />
          <span class="self-center text-2xl font-bold whitespace-nowrap text-primary-800">TaskFlow</span>
      </router-link>

      <!-- Botón móvil -->
      <button
        @click="toggleMobileMenu"
        type="button"
        class="inline-flex items-center p-2 w-10 h-10 justify-center text-sm text-primary-600 rounded-lg md:hidden hover:bg-primary-200 focus:outline-none focus:ring-2 focus:ring-primary-300 transition-colors duration-200"
        aria-controls="navbar-default"
        :aria-expanded="isMobileMenuOpen">
          <span class="sr-only">Abrir menú principal</span>
          <Bars3Icon class="w-5 h-5" />
      </button>

      <!-- Menú de navegación -->
      <div
        :class="{ 'hidden': !isMobileMenuOpen }"
        class="w-full md:block md:w-auto"
        id="navbar-default">
        <ul class="font-medium flex flex-col p-4 md:p-0 mt-4 border border-primary-200 rounded-lg bg-primary-50 md:flex-row md:space-x-6 rtl:space-x-reverse md:mt-0 md:border-0 md:bg-transparent">
          <li>
            <router-link
              to="/mis-tareas"
              class="flex items-center space-x-2 py-2 px-4 rounded-lg transition-all duration-200 font-semibold"
              :class="isActiveRoute('/mis-tareas') ?
                'text-white bg-primary-500 shadow-sm md:bg-transparent md:text-primary-600 md:shadow-none' :
                'text-primary-700 hover:bg-primary-200 md:hover:bg-transparent md:hover:text-primary-500'"
              @click="closeMobileMenu">
              <ClipboardDocumentListIcon class="w-5 h-5" />
              <span>Mis Tareas</span>
            </router-link>
          </li>
          <li>
            <router-link
              to="/mis-tareas-completadas"
              class="flex items-center space-x-2 py-2 px-4 rounded-lg transition-all duration-200"
              :class="isActiveRoute('/mis-tareas-completadas') ?
                'text-white bg-primary-500 shadow-sm md:bg-transparent md:text-primary-600 md:shadow-none font-semibold' :
                'text-primary-700 hover:bg-primary-200 md:hover:bg-transparent md:hover:text-primary-500 hover:font-semibold'"
              @click="closeMobileMenu">
              <CheckCircleIcon class="w-5 h-5" />
              <span>Completadas</span>
            </router-link>
          </li>
          <li>
            <router-link
              to="/estadisticas"
              class="flex items-center space-x-2 py-2 px-4 rounded-lg transition-all duration-200"
              :class="isActiveRoute('/estadisticas') ?
                'text-white bg-primary-500 shadow-sm md:bg-transparent md:text-primary-600 md:shadow-none font-semibold' :
                'text-primary-700 hover:bg-primary-200 md:hover:bg-transparent md:hover:text-primary-500 hover:font-semibold'"
              @click="closeMobileMenu">
              <ChartBarIcon class="w-5 h-5" />
              <span>Estadísticas</span>
            </router-link>
          </li>
          <li>
            <router-link
              to="/configuracion"
              class="flex items-center space-x-2 py-2 px-4 rounded-lg transition-all duration-200"
              :class="isActiveRoute('/configuracion') ?
                'text-white bg-primary-500 shadow-sm md:bg-transparent md:text-primary-600 md:shadow-none font-semibold' :
                'text-primary-700 hover:bg-primary-200 md:hover:bg-transparent md:hover:text-primary-500 hover:font-semibold'"
              @click="closeMobileMenu">
              <Cog6ToothIcon class="w-5 h-5" />
              <span>Configuración</span>
            </router-link>
          </li>
          <li>
            <button
              @click="handleNewTaskClick"
              class="flex items-center space-x-2 py-2 px-4 text-white bg-accent rounded-lg hover:bg-accent-light transition-all duration-200 font-semibold shadow-sm w-full md:w-auto">
              <PlusCircleIcon class="w-5 h-5" />
              <span>Nueva Tarea</span>
            </button>
          </li>
        </ul>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import {
  Bars3Icon,
  ClipboardDocumentListIcon,
  CheckCircleIcon,
  ChartBarIcon,
  Cog6ToothIcon,
  PlusCircleIcon
} from '@heroicons/vue/24/outline'
import { useNewTaskModal } from '@/composables/useNewTaskModal'

// Composables
const route = useRoute()
const { openModal } = useNewTaskModal()

// Estado reactivo
const isMobileMenuOpen = ref(false)
const isMobileMenu = ref(window.innerWidth < 768)
// Métodos
const toggleMobileMenu = () => {
  isMobileMenuOpen.value = !isMobileMenu.value
}

const closeMobileMenu = () => {
  isMobileMenuOpen.value = false
}

const isActiveRoute = (path) => {
  return route.path === path
}

const handleNewTaskClick = () => {
  openModal()
  closeMobileMenu()
}
</script>

<style scoped>
/* Estilos adicionales si son necesarios */
</style>
