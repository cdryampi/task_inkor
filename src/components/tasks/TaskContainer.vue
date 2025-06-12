<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-primary-800">Mis Tareas</h1>
      <!-- ✅ QUITAR BOTÓN NUEVA TAREA - Solo disponible desde navbar -->
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
        @update-task="handleUpdateTask"
        @delete-task="handleDeleteTask"
        @update-status="handleUpdateStatus"
      />
    </div>

    <!-- Empty state -->
    <div v-if="!loading && allTasks.length === 0" class="text-center py-12">
      <ClipboardDocumentListIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <p class="text-gray-500 mb-4">No tienes tareas</p>
      <p class="text-sm text-gray-400">
        Crea tu primera tarea usando el botón "Nueva" en la barra de navegación
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  ClipboardDocumentListIcon,
  ClockIcon,
  CheckCircleIcon
} from '@heroicons/vue/24/outline'
import { useSupabase } from '@/hooks/supabase'
import TaskCard from '@/components/tasks/TaskCard.vue'

const route = useRoute()
const {
  tasks,
  loading,
  error,
  getTasks,
  updateTask,
  toggleTaskStatus,
  deleteTask
} = useSupabase()

// Computadas para los contadores
const allTasks = computed(() => {
  return tasks.value.sort((a, b) => {
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

// Formatear tarea para el TaskCard
const formatTaskForCard = (task) => {
  return {
    id: task.id,
    title: task.title,
    description: task.description,
    status: task.status,
    priority: task.priority || 'normal',
    dueDate: task.due_date,
    dueTime: task.due_time,
    tags: task.tags || []
  }
}

// ✅ QUITAR handleEditTask - Ahora TaskCard maneja la navegación internamente

// Handle delete task
const handleDeleteTask = async (taskId) => {
  if (confirm('¿Estás seguro de que quieres eliminar esta tarea?')) {
    try {
      console.log('🗑️ TaskContainer - Eliminando tarea:', taskId)
      await deleteTask(taskId)
      console.log('✅ TaskContainer - Tarea eliminada exitosamente')
    } catch (err) {
      console.error('❌ TaskContainer - Error eliminando tarea:', err)
    }
  }
}

// Handle update status
const handleUpdateStatus = async (taskId, newStatus) => {
  try {
    console.log('🔄 TaskContainer - Actualizando estado:', taskId, newStatus)
    await toggleTaskStatus(taskId, newStatus)
    console.log('✅ TaskContainer - Estado actualizado exitosamente')
  } catch (err) {
    console.error('❌ TaskContainer - Error actualizando estado:', err)
  }
}

// ✅ NUEVO: Manejar actualización de tarea desde TaskCard
const handleUpdateTask = async (taskData) => {
  try {
    console.log('🔄 TaskContainer - Actualizando tarea desde TaskCard:', taskData)
    await updateTask(taskData.id, taskData)
    console.log('✅ TaskContainer - Tarea actualizada exitosamente')
  } catch (err) {
    console.error('❌ TaskContainer - Error actualizando tarea:', err)
  }
}

// Cargar tareas al montar
onMounted(async () => {
  console.log('🔄 TaskContainer - Cargando tareas')
  await getTasks()
})
</script>

<style lang="scss" scoped>
</style>
