<template>
  <nav class="bg-white border-b border-gray-200 shadow-sm">
    <div class="max-w-screen-xl flex items-center justify-between mx-auto px-6 py-4">
      <!-- Logo y título minimalista -->
      <router-link to="/" class="flex items-center space-x-3 group">
        <div class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
          <span class="text-white font-bold text-sm">I</span>
        </div>
        <div>
          <span class="text-xl font-semibold text-gray-900">InkorTask</span>
          <span class="text-xs text-gray-500 block leading-none">Professional</span>
        </div>
      </router-link>

      <!-- Botón móvil minimalista -->
      <button
        @click="toggleMobileMenu"
        type="button"
        class="p-2 text-gray-500 rounded-md md:hidden hover:text-gray-700 hover:bg-gray-100 transition-colors"
        aria-controls="navbar-menu"
        :aria-expanded="isMobileMenuOpen">
        <span class="sr-only">Menú</span>
        <Bars3Icon class="w-5 h-5" />
      </button>

      <!-- Menú de navegación -->
      <div
        :class="{ 'hidden': !isMobileMenuOpen }"
        class="w-full md:block md:w-auto md:flex md:items-center"
        id="navbar-menu">

        <!-- Links principales -->
        <ul class="flex flex-col md:flex-row md:space-x-1 mt-4 md:mt-0 space-y-1 md:space-y-0">
          <li>
            <router-link
              to="/mis-tareas"
              class="nav-link"
              :class="{ 'nav-link-active': isActiveRoute('/mis-tareas') }"
              @click="closeMobileMenu">
              <ClipboardDocumentListIcon class="w-4 h-4" />
              <span>Tareas</span>
            </router-link>
          </li>

          <li>
            <router-link
              to="/calendario"
              class="nav-link"
              :class="{ 'nav-link-active': isActiveRoute('/calendario') }"
              @click="closeMobileMenu">
              <CalendarIcon class="w-4 h-4" />
              <span>Calendario</span>
            </router-link>
          </li>

          <li>
            <router-link
              to="/estadisticas"
              class="nav-link"
              :class="{ 'nav-link-active': isActiveRoute('/estadisticas') }"
              @click="closeMobileMenu">
              <ChartBarIcon class="w-4 h-4" />
              <span>Analytics</span>
            </router-link>
          </li>
        </ul>

        <!-- Separador -->
        <div class="hidden md:block w-px h-6 bg-gray-300 mx-4"></div>

        <!-- Botón CTA -->
        <div class="mt-4 md:mt-0">
          <button
            @click="handleNewTask"
            class="cta-button">
            <PlusIcon class="w-4 h-4" />
            <span>Nueva</span>
          </button>
        </div>

        <!-- Menú secundario (móvil) -->
        <div class="md:hidden mt-4 pt-4 border-t border-gray-200">
          <ul class="space-y-1">
            <li>
              <router-link
                to="/mis-tareas-completadas"
                class="nav-link-secondary"
                :class="{ 'nav-link-secondary-active': isActiveRoute('/mis-tareas-completadas') }"
                @click="closeMobileMenu">
                <CheckCircleIcon class="w-4 h-4" />
                <span>Completadas</span>
              </router-link>
            </li>
            <li>
              <router-link
                to="/configuracion"
                class="nav-link-secondary"
                :class="{ 'nav-link-secondary-active': isActiveRoute('/configuracion') }"
                @click="closeMobileMenu">
                <Cog6ToothIcon class="w-4 h-4" />
                <span>Configuración</span>
              </router-link>
            </li>
          </ul>
        </div>
      </div>

      <!-- Menú secundario (desktop) -->
      <div class="hidden md:flex items-center space-x-1">
        <router-link
          to="/mis-tareas-completadas"
          class="nav-icon"
          :class="{ 'nav-icon-active': isActiveRoute('/mis-tareas-completadas') }"
          title="Completadas">
          <CheckCircleIcon class="w-5 h-5" />
        </router-link>

        <router-link
          to="/configuracion"
          class="nav-icon"
          :class="{ 'nav-icon-active': isActiveRoute('/configuracion') }"
          title="Configuración">
          <Cog6ToothIcon class="w-5 h-5" />
        </router-link>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import {
  PlusIcon,
  CheckCircleIcon,
  Cog6ToothIcon,
  Bars3Icon,
  XMarkIcon
} from '@heroicons/vue/24/outline'
import { useNewTaskModal } from '@/composables/useNewTaskModal'

// Composables
const route = useRoute()
const { openModal } = useNewTaskModal()

// Estado reactivo
const isMobileMenuOpen = ref(false)

// Método para nueva tarea
const handleNewTask = () => {
  console.log('🆕 NavBar - Activando modal global para nueva tarea')
  console.log('🔧 NavBar - Ruta actual:', route.path)
  openModal()
}

// Métodos para navegación
const isActiveRoute = (routePath) => {
  return route.path === routePath
}

const closeMobileMenu = () => {
  isMobileMenuOpen.value = false
}

const toggleMobileMenu = () => {
  isMobileMenuOpen.value = !isMobileMenuOpen.value
}
</script>

<style scoped>
/* Links principales */
.nav-link {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: #6b7280;
  border-radius: 0.375rem;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  text-decoration: none;
}

.nav-link:hover {
  color: #111827;
  background-color: #f3f4f6;
  transform: translateY(-1px);
}

.nav-link-active {
  color: #059669;
  background-color: #ecfdf5;
}

.nav-link-active:hover {
  color: #047857;
  background-color: #d1fae5;
}

/* Links secundarios (móvil) */
.nav-link-secondary {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
  color: #9ca3af;
  border-radius: 0.375rem;
  transition: color 0.2s ease, background-color 0.2s ease;
  text-decoration: none;
}

.nav-link-secondary:hover {
  color: #374151;
  background-color: #f9fafb;
}

.nav-link-secondary-active {
  color: #059669;
  background-color: #ecfdf5;
}

/* Iconos (desktop) */
.nav-icon {
  padding: 0.5rem;
  color: #9ca3af;
  border-radius: 0.375rem;
  transition: all 0.2s ease;
  text-decoration: none;
  display: flex;
  align-items: center;
  justify-content: center;
}

.nav-icon:hover {
  color: #6b7280;
  background-color: #f3f4f6;
  transform: scale(1.05);
}

.nav-icon-active {
  color: #059669;
  background-color: #ecfdf5;
}

.nav-icon-active:hover {
  color: #047857;
}

/* Botón CTA */
.cta-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: white;
  background-color: #059669;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  width: 100%;
  justify-content: center;
}

.cta-button:hover {
  background-color: #047857;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  transform: translateY(-1px);
}

.cta-button:focus {
  outline: none;
  box-shadow: 0 0 0 2px #10b981, 0 0 0 4px rgba(16, 185, 129, 0.1);
}

/* Responsive ajustes */
@media (min-width: 768px) {
  .cta-button {
    width: auto;
    justify-content: flex-start;
  }

  #navbar-menu {
    position: static !important;
    background: transparent !important;
    border: none !important;
    box-shadow: none !important;
    padding: 0 !important;
  }
}

@media (max-width: 767px) {
  #navbar-menu {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    background-color: white;
    border-top: 1px solid #e5e7eb;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
    padding: 0 1.5rem 1rem;
    z-index: 50;
  }

  #navbar-menu.hidden {
    display: none;
  }
}

/* Animación del logo hover */
.group:hover .w-8 {
  transform: rotate(5deg) scale(1.05);
  transition: transform 0.2s ease;
}

/* Separador responsivo */
@media (max-width: 767px) {
  .w-px {
    display: none;
  }
}
</style>
