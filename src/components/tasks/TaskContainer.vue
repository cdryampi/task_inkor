<template>
  <div class="container mx-auto p-4">
    <!-- Header sin botón duplicado -->
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-primary-800">Mis Tareas</h1>
      <!-- Mostrar botón solo en páginas donde tenga sentido -->
      <button
        v-if="showLocalButton"
        @click="openModal"
        class="flex items-center space-x-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors font-semibold shadow-sm">
        <PlusCircleIcon class="w-5 h-5" />
        <span>Nueva Tarea</span>
      </button>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="text-center py-8">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      <p class="mt-2 text-primary-600">Cargando tareas...</p>
    </div>

    <!-- Error state -->
    <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
      {{ error }}
    </div>

    <!-- Tasks list -->
    <div v-if="!loading && pendingTasks.length > 0" class="space-y-4">
      <div
        v-for="task in pendingTasks"
        :key="task.id"
        class="bg-white p-4 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
        <h3 class="font-semibold text-gray-800">{{ task.title }}</h3>
        <p v-if="task.description" class="text-gray-600 mt-1">{{ task.description }}</p>
        <div class="mt-3 flex space-x-2">
          <button
            @click="toggleTaskStatus(task.id, task.status)"
            class="flex items-center space-x-1 px-3 py-1 bg-primary-500 text-white rounded hover:bg-primary-600 transition-colors">
            <CheckCircleIcon class="w-4 h-4" />
            <span>Completar</span>
          </button>
          <button
            @click="deleteTask(task.id)"
            class="flex items-center space-x-1 px-3 py-1 bg-red-500 text-white rounded hover:bg-red-600 transition-colors">
            <TrashIcon class="w-4 h-4" />
            <span>Eliminar</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-if="!loading && pendingTasks.length === 0" class="text-center py-12">
      <ClipboardDocumentListIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <p class="text-gray-500 mb-4">No tienes tareas pendientes</p>
      <button
        @click="showNewTaskModal = true"
        class="inline-flex items-center space-x-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors">
        <PlusCircleIcon class="w-5 h-5" />
        <span>Crear tu primera tarea</span>
      </button>
    </div>

    <!-- Modal de nueva tarea usando el estado global -->
    <NewTaskModal
      :isOpen="isModalOpen"
      :loading="creatingTask"
      @close="closeModal"
      @submit="handleCreateTask" />
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  ClipboardDocumentListIcon,
  PlusCircleIcon,
  CheckCircleIcon,
  TrashIcon
} from '@heroicons/vue/24/outline'
import { useSupabase } from '@/hooks/supabase'
import { useNewTaskModal } from '@/composables/useNewTaskModal'
import NewTaskModal from '@/components/modals/NewTaskModal.vue'

const route = useRoute()
const {
  pendingTasks,
  loading,
  error,
  getTasks,
  createTask,
  toggleTaskStatus,
  deleteTask
} = useSupabase()

const { isModalOpen, openModal, closeModal } = useNewTaskModal()

// Solo mostrar botón local en ciertas páginas
const showLocalButton = computed(() => {
  return route.path === '/mis-tareas' && pendingTasks.value.length === 0
})

const creatingTask = ref(false)

// Handle create task
const handleCreateTask = async (taskData) => {
  creatingTask.value = true
  try {
    await createTask(taskData)
    closeModal()
    console.log('✅ Tarea creada exitosamente')
  } catch (err) {
    console.error('❌ Error creando tarea:', err)
  } finally {
    creatingTask.value = false
  }
}

// Cargar tareas al montar el componente
onMounted(async () => {
  await getTasks()
})
</script>

<style lang="scss" scoped>

</style>
