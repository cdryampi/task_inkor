<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-primary-800">Mis Tareas</h1>
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

    <!-- Barra de resumen de tareas -->
    <div v-if="!loading" class="mb-6 grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-yellow-100 rounded-lg">
            <ClockIcon class="w-5 h-5 text-yellow-600" />
          </div>
          <div>
            <p class="text-sm text-gray-600">Pendientes</p>
            <p class="text-lg font-semibold text-gray-800">{{ pendingTasksCount }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-blue-100 rounded-lg">
            <ClipboardDocumentListIcon class="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <p class="text-sm text-gray-600">En Progreso</p>
            <p class="text-lg font-semibold text-gray-800">{{ inProgressTasksCount }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-green-100 rounded-lg">
            <CheckCircleIcon class="w-5 h-5 text-green-600" />
          </div>
          <div>
            <p class="text-sm text-gray-600">Completadas</p>
            <p class="text-lg font-semibold text-gray-800">{{ completedTasksCount }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Tasks list usando TaskCard -->
    <div v-if="!loading && allTasks.length > 0" class="space-y-4">
      <TaskCard
        v-for="task in allTasks"
        :key="task.id"
        :task="formatTaskForCard(task)"
        @edit-task="handleEditTask"
        @delete-task="handleDeleteTask"
        @update-status="handleUpdateStatus"
      />
    </div>

    <!-- Empty state -->
    <div v-if="!loading && allTasks.length === 0" class="text-center py-12">
      <ClipboardDocumentListIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <p class="text-gray-500 mb-4">No tienes tareas</p>
      <button
        @click="openModal"
        class="inline-flex items-center space-x-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors">
        <PlusCircleIcon class="w-5 h-5" />
        <span>Crear tu primera tarea</span>
      </button>
    </div>

    <!-- Modal de nueva/editar tarea -->
    <NewTaskModal
      :isOpen="isModalOpen"
      :loading="creatingTask"
      :editTask="editingTask"
      @close="handleCloseModal"
      @submit="handleCreateTask"
      @update="handleUpdateTask" />
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  ClipboardDocumentListIcon,
  PlusCircleIcon,
  ClockIcon,
  CheckCircleIcon
} from '@heroicons/vue/24/outline'
import { useSupabase } from '@/hooks/supabase'
import { useNewTaskModal } from '@/composables/useNewTaskModal'
import NewTaskModal from '@/components/modals/NewTaskModal.vue'
import TaskCard from '@/components/tasks/TaskCard.vue'

const route = useRoute()
const {
  tasks,
  pendingTasks,
  completedTasks,
  loading,
  error,
  getTasks,
  createTask,
  updateTask,
  toggleTaskStatus,
  deleteTask
} = useSupabase()

const { isModalOpen, openModal, closeModal } = useNewTaskModal()

// Solo mostrar botón local en ciertas páginas
const showLocalButton = computed(() => {
  return route.path === '/mis-tareas' && allTasks.value.length === 0
})

const creatingTask = ref(false)
const editingTask = ref(null) // Nueva ref para la tarea en edición

// Computadas para los contadores
const allTasks = computed(() => {
  return tasks.value.sort((a, b) => {
    // Ordenar por estado (pendientes primero) y luego por prioridad
    if (a.status !== b.status) {
      const statusOrder = { 'pending': 0, 'in-progress': 1, 'completed': 2 }
      return statusOrder[a.status] - statusOrder[b.status]
    }

    const priorityOrder = { high: 3, medium: 2, normal: 1 }
    return (priorityOrder[b.priority] || 1) - (priorityOrder[a.priority] || 1)
  })
})

const pendingTasksCount = computed(() => {
  return tasks.value.filter(task => task.status === 'pending').length
})

const inProgressTasksCount = computed(() => {
  return tasks.value.filter(task => task.status === 'in-progress').length
})

const completedTasksCount = computed(() => {
  return tasks.value.filter(task => task.status === 'completed').length
})

// Formatear tarea para el TaskCard (incluyendo hora)
const formatTaskForCard = (task) => {
  return {
    id: task.id,
    title: task.title,
    description: task.description,
    status: task.status,
    priority: task.priority || 'normal',
    dueDate: task.due_date,
    dueTime: task.due_time, // Añadimos la hora
    tags: task.tags || []
  }
}

// Handle edit task
const handleEditTask = (task) => {
  console.log('Editar tarea:', task)
  editingTask.value = task
  openModal()
}

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
    editingTask.value = null
  }
}

// Handle update task
const handleUpdateTask = async (taskData) => {
  creatingTask.value = true
  try {
    await updateTask(taskData.id, taskData)
    closeModal()
    console.log('✅ Tarea actualizada exitosamente')
  } catch (err) {
    console.error('❌ Error actualizando tarea:', err)
  } finally {
    creatingTask.value = false
    editingTask.value = null
  }
}

// Handle close modal
const handleCloseModal = () => {
  editingTask.value = null
  closeModal()
}

// Handle delete task
const handleDeleteTask = async (taskId) => {
  if (confirm('¿Estás seguro de que quieres eliminar esta tarea?')) {
    try {
      await deleteTask(taskId)
      console.log('✅ Tarea eliminada exitosamente')
    } catch (err) {
      console.error('❌ Error eliminando tarea:', err)
    }
  }
}

// Handle update status
const handleUpdateStatus = async (taskId, newStatus) => {
  try {
    await toggleTaskStatus(taskId, newStatus)
    console.log('✅ Estado actualizado exitosamente')
  } catch (err) {
    console.error('❌ Error actualizando estado:', err)
  }
}

// Cargar tareas al montar el componente
onMounted(async () => {
  await getTasks()
})
</script>

<style lang="scss" scoped>
</style>
