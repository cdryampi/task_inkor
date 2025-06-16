<template>
  <div id="app">
    <Notivue v-slot="item">
      <Notification :item="item" />
    </Notivue>
    <NavBarComponent />
    <router-view />

    <!-- ✅ MODAL GLOBAL FUNCIONAL -->
    <NewTaskModal
      :isOpen="isGlobalModalOpen"
      :loading="creatingTask"
      @close="closeGlobalModal"
      @submit="handleCreateTask" />
  </div>
</template>

<script setup>
import { ref } from 'vue'
import NavBarComponent from '@/components/custom/NavBarComponent.vue'
import NewTaskModal from '@/components/modals/NewTaskModal.vue'
import { useNewTaskModal } from '@/composables/useNewTaskModal'
import { useSupabase } from '@/hooks/supabase'
import { Notivue, Notification } from 'notivue'

// Estado global del modal
const { isModalOpen: isGlobalModalOpen, closeModal } = useNewTaskModal()

// Hook de Supabase para crear tareas
const { createTask } = useSupabase()

// Estado para loading
const creatingTask = ref(false)

// Método para cerrar modal
const closeGlobalModal = () => {
  console.log('🔄 App.vue - Cerrando modal global')
  closeModal()
}

// Método para crear tarea desde navbar
const handleCreateTask = async (taskData) => {
  creatingTask.value = true
  try {
    console.log('🚀 App.vue - Creando tarea desde navbar:', taskData)
    await createTask(taskData)
    closeGlobalModal()
    console.log('✅ App.vue - Tarea creada exitosamente desde navbar')
  } catch (err) {
    console.error('❌ App.vue - Error creando tarea desde navbar:', err)
  } finally {
    creatingTask.value = false
  }
}
</script>

<style scoped>
header {
  line-height: 1.5;
  max-height: 100vh;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

nav {
  width: 100%;
  font-size: 12px;
  text-align: center;
  margin-top: 2rem;
}

nav a.router-link-exact-active {
  color: var(--color-text);
}

nav a.router-link-exact-active:hover {
  background-color: transparent;
}

nav a {
  display: inline-block;
  padding: 0 1rem;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  .logo {
    margin: 0 2rem 0 0;
  }

  header .wrapper {
    display: flex;
    place-items: flex-start;
    flex-wrap: wrap;
  }

  nav {
    text-align: left;
    margin-left: -1rem;
    font-size: 1rem;

    padding: 1rem 0;
    margin-top: 1rem;
  }
}
</style>

<style>
  /* ✅ FORZAR ESTILOS DEL MODAL */
  [style*="z-index: 99999"] {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    width: 100vw !important;
    height: 100vh !important;
    display: flex !important;
    z-index: 99999 !important;
  }
</style>
