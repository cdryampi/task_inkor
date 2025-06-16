<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-primary-800">Mis Tareas</h1>
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

    <!-- Task Filters -->
    <TaskFilter
      v-if="!loading"
      :filters="filters"
      @update:filters="updateFilters"
    />

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

    <!-- Results count -->
    <div v-if="!loading && filteredTasks.length !== allTasks.length" class="mb-4">
      <p class="text-sm text-gray-600">
        Mostrando {{ filteredTasks.length }} de {{ allTasks.length }} tareas
        <span v-if="isLimitedView" class="text-primary-600">(limitado a 10 por rendimiento)</span>
      </p>
    </div>

    <!-- Tasks list usando TaskCard -->
    <div v-if="!loading && filteredTasks.length > 0" class="space-y-4">
      <TaskCard
        v-for="task in filteredTasks"
        :key="task.id"
        :task="formatTaskForCard(task)"
        @update-task="handleUpdateTask"
        @delete-task="handleDeleteTask"
        @update-status="handleUpdateStatus"
      />
    </div>

    <!-- Empty state -->
    <div v-if="!loading && filteredTasks.length === 0 && allTasks.length === 0" class="text-center py-12">
      <ClipboardDocumentListIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <p class="text-gray-500 mb-4">No tienes tareas</p>
      <p class="text-sm text-gray-400">
        Crea tu primera tarea usando el botón "Nueva" en la barra de navegación
      </p>
    </div>

    <!-- No results state -->
    <div v-if="!loading && filteredTasks.length === 0 && allTasks.length > 0" class="text-center py-12">
      <MagnifyingGlassIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <p class="text-gray-500 mb-4">No se encontraron tareas con los filtros aplicados</p>
      <button
        @click="clearFilters"
        class="text-primary-600 hover:text-primary-700 text-sm">
        Limpiar filtros
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import {
  ClipboardDocumentListIcon,
  ClockIcon,
  CheckCircleIcon,
  MagnifyingGlassIcon
} from '@heroicons/vue/24/outline'
import { useSupabase } from '@/hooks/supabase'
import TaskCard from '@/components/tasks/TaskCard.vue'
import TaskFilter from '@/components/tasks/TaskFilter.vue'

const route = useRoute()
const {
  tasks,
  loading,
  error,
  getTasks,
  getTodaysTasks, // ✅ NUEVO
  getUpcomingTasks, // ✅ NUEVO
  updateTask,
  toggleTaskStatus,
  deleteTask
} = useSupabase()

// ✅ FILTROS CON VALORES POR DEFECTO PARA HOY
const filters = ref({
  status: '',
  priority: '',
  dueDate: 'today', // ✅ POR DEFECTO HOY
  search: '',
  sortBy: 'due_time', // ✅ POR DEFECTO HORA
  sortOrder: 'asc'
})

// ✅ INDICADOR SI ESTAMOS EN VISTA LIMITADA
const isLimitedView = computed(() => {
  return filters.value.dueDate === 'today' || filters.value.dueDate === 'upcoming'
})

// Update filters
const updateFilters = (newFilters) => {
  filters.value = { ...newFilters }
}

const clearFilters = () => {
  filters.value = {
    status: '',
    priority: '',
    dueDate: 'today', // ✅ RESETEAR A HOY
    search: '',
    sortBy: 'due_time', // ✅ RESETEAR A HORA
    sortOrder: 'asc'
  }
}

// ✅ FUNCIÓN MEJORADA PARA CARGAR TAREAS SEGÚN FILTROS
const loadTasksBasedOnFilters = async () => {
  try {
    console.log('🔄 Cargando tareas con filtros:', filters.value)

    // Usar métodos específicos para casos optimizados
    if (filters.value.dueDate === 'today') {
      console.log('📅 Cargando tareas de hoy (límite 10)')
      await getTodaysTasks(10)
    } else if (filters.value.dueDate === 'upcoming') {
      console.log('🔮 Cargando tareas próximas (límite 10)')
      await getUpcomingTasks(10)
    } else {
      console.log('📋 Cargando todas las tareas')
      await getTasks()
    }
  } catch (err) {
    console.error('❌ Error cargando tareas:', err)
  }
}

// ✅ WATCH PARA RECARGAR CUANDO CAMBIE EL FILTRO DE FECHA
watch(
  () => filters.value.dueDate,
  (newDueDate, oldDueDate) => {
    console.log('🔄 Filtro de fecha cambió:', { oldDueDate, newDueDate })

    // Solo recargar si es un cambio significativo que requiere nuevos datos
    if ((oldDueDate === 'today' || oldDueDate === 'upcoming') ||
        (newDueDate === 'today' || newDueDate === 'upcoming')) {
      loadTasksBasedOnFilters()
    }
  }
)

// Helper function to check if date matches filter
const matchesDueDateFilter = (task, filter) => {
  if (!filter) return true

  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const tomorrow = new Date(today)
  tomorrow.setDate(tomorrow.getDate() + 1)

  if (!task.due_date) {
    return filter === 'no-date'
  }

  const dueDate = new Date(task.due_date)
  const dueDateOnly = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate())

  switch (filter) {
    case 'overdue':
      return dueDateOnly < today
    case 'today':
      return dueDateOnly.getTime() === today.getTime()
    case 'tomorrow':
      return dueDateOnly.getTime() === tomorrow.getTime()
    case 'this-week':
      const weekFromNow = new Date(today)
      weekFromNow.setDate(weekFromNow.getDate() + 7)
      return dueDateOnly >= today && dueDateOnly <= weekFromNow
    case 'next-week':
      const nextWeekStart = new Date(today)
      nextWeekStart.setDate(nextWeekStart.getDate() + 7)
      const nextWeekEnd = new Date(nextWeekStart)
      nextWeekEnd.setDate(nextWeekEnd.getDate() + 7)
      return dueDateOnly >= nextWeekStart && dueDateOnly <= nextWeekEnd
    case 'upcoming':
      return dueDateOnly >= today
    case 'no-date':
      return false // Ya se maneja arriba
    default:
      return true
  }
}

// Filtered and sorted tasks
const filteredTasks = computed(() => {
  let filtered = [...tasks.value]

  // ✅ PARA CASOS OPTIMIZADOS, LA FILTRACIÓN YA SE HIZO EN LA BASE DE DATOS
  if (filters.value.dueDate === 'today' || filters.value.dueDate === 'upcoming') {
    // Solo aplicar filtros adicionales
    if (filters.value.status) {
      filtered = filtered.filter(task => task.status === filters.value.status)
    }

    if (filters.value.priority) {
      filtered = filtered.filter(task => task.priority === filters.value.priority)
    }

    if (filters.value.search) {
      const searchTerm = filters.value.search.toLowerCase()
      filtered = filtered.filter(task =>
        task.title.toLowerCase().includes(searchTerm) ||
        (task.description && task.description.toLowerCase().includes(searchTerm))
      )
    }

    return filtered // Ya están ordenados desde la BD
  }

  // Apply filters para otros casos
  if (filters.value.status) {
    filtered = filtered.filter(task => task.status === filters.value.status)
  }

  if (filters.value.priority) {
    filtered = filtered.filter(task => task.priority === filters.value.priority)
  }

  if (filters.value.dueDate) {
    filtered = filtered.filter(task => matchesDueDateFilter(task, filters.value.dueDate))
  }

  if (filters.value.search) {
    const searchTerm = filters.value.search.toLowerCase()
    filtered = filtered.filter(task =>
      task.title.toLowerCase().includes(searchTerm) ||
      (task.description && task.description.toLowerCase().includes(searchTerm))
    )
  }

  // Apply sorting
  filtered.sort((a, b) => {
    let comparison = 0

    switch (filters.value.sortBy) {
      case 'title':
        comparison = a.title.localeCompare(b.title)
        break
      case 'due_date':
        if (!a.due_date && !b.due_date) comparison = 0
        else if (!a.due_date) comparison = 1
        else if (!b.due_date) comparison = -1
        else comparison = new Date(a.due_date) - new Date(b.due_date)
        break
      case 'due_time':
        if (!a.due_time && !b.due_time) comparison = 0
        else if (!a.due_time) comparison = 1
        else if (!b.due_time) comparison = -1
        else comparison = a.due_time.localeCompare(b.due_time)
        break
      case 'priority':
        const priorityOrder = { high: 3, medium: 2, normal: 1 }
        comparison = (priorityOrder[b.priority] || 1) - (priorityOrder[a.priority] || 1)
        break
      case 'status':
        const statusOrder = { pending: 0, 'in-progress': 1, 'on-hold': 2, completed: 3, cancelled: 4 }
        comparison = statusOrder[a.status] - statusOrder[b.status]
        break
      case 'created_at':
      default:
        comparison = new Date(a.created_at) - new Date(b.created_at)
        break
    }

    return filters.value.sortOrder === 'asc' ? comparison : -comparison
  })

  return filtered
})

// All tasks (for original sorting when no filters)
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

// Task counters (based on all tasks, not filtered)
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

const handleUpdateStatus = async (taskId, newStatus) => {
  try {
    console.log('🔄 TaskContainer - Actualizando estado:', taskId, newStatus)
    await toggleTaskStatus(taskId, newStatus)
    console.log('✅ TaskContainer - Estado actualizado exitosamente')
  } catch (err) {
    console.error('❌ TaskContainer - Error actualizando estado:', err)
  }
}

const handleUpdateTask = async (taskData) => {
  try {
    console.log('🔄 TaskContainer - Actualizando tarea desde TaskCard:', taskData)
    await updateTask(taskData.id, taskData)
    console.log('✅ TaskContainer - Tarea actualizada exitosamente')
  } catch (err) {
    console.error('❌ TaskContainer - Error actualizando tarea:', err)
  }
}

onMounted(async () => {
  console.log('🔄 TaskContainer - Cargando tareas iniciales')
  await loadTasksBasedOnFilters()
})
</script>

<style lang="scss" scoped>
</style>
