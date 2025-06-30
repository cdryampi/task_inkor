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

    <!-- ✅ Controles de paginación y tareas por página -->
    <div v-if="!loading && filteredTasks.length > 0" class="mb-4 bg-white p-4 rounded-lg shadow-sm border border-gray-200">
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <!-- Info de resultados -->
        <div>
          <p class="text-sm text-gray-600">
            Mostrando {{ startIndex + 1 }}-{{ Math.min(endIndex, filteredTasks.length) }} de {{ filteredTasks.length }} tareas
            <span v-if="isLimitedView" class="text-primary-600">(vista optimizada)</span>
          </p>
        </div>

        <!-- Controles -->
        <div class="flex items-center gap-4">
          <!-- Tareas por página -->
          <div class="flex items-center gap-2">
            <label class="text-sm text-gray-600">Por página:</label>
            <select
              v-model="itemsPerPage"
              @change="resetPagination"
              class="px-2 py-1 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            >
              <option :value="5">5</option>
              <option :value="10">10</option>
              <option :value="20">20</option>
              <option :value="50">50</option>
            </select>
          </div>

          <!-- Mini paginador (solo si hay muchas páginas) -->
          <div v-if="totalPages > 1" class="text-sm text-gray-500">
            Página {{ currentPage }} de {{ totalPages }}
          </div>
        </div>
      </div>
    </div>

    <!-- ✅ Tasks list paginadas usando TaskCard -->
    <div v-if="!loading && paginatedTasks.length > 0" class="space-y-4">
      <TaskCard
        v-for="task in paginatedTasks"
        :key="task.id"
        :task="formatTaskForCard(task)"
        @update-task="handleUpdateTask"
        @delete-task="handleDeleteTask"
        @update-status="handleUpdateStatus"
      />
    </div>

    <!-- ✅ Paginador principal -->
    <div v-if="!loading && filteredTasks.length > 0 && totalPages > 1" class="mt-8 flex items-center justify-center">
      <nav class="flex items-center space-x-2">
        <!-- Botón primera página -->
        <button
          @click="goToPage(1)"
          :disabled="currentPage === 1"
          class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          title="Primera página"
        >
          ««
        </button>

        <!-- Botón página anterior -->
        <button
          @click="goToPage(currentPage - 1)"
          :disabled="currentPage === 1"
          class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          title="Página anterior"
        >
          ‹
        </button>

        <!-- Números de página -->
        <template v-for="page in visiblePages" :key="page">
          <button
            v-if="page !== '...'"
            @click="goToPage(page)"
            :class="[
              'px-3 py-2 text-sm font-medium rounded-lg',
              page === currentPage
                ? 'text-white bg-primary-600 border border-primary-600'
                : 'text-gray-500 bg-white border border-gray-300 hover:bg-gray-50'
            ]"
          >
            {{ page }}
          </button>
          <span v-else class="px-3 py-2 text-sm text-gray-400">...</span>
        </template>

        <!-- Botón página siguiente -->
        <button
          @click="goToPage(currentPage + 1)"
          :disabled="currentPage === totalPages"
          class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          title="Página siguiente"
        >
          ›
        </button>

        <!-- Botón última página -->
        <button
          @click="goToPage(totalPages)"
          :disabled="currentPage === totalPages"
          class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          title="Última página"
        >
          »»
        </button>
      </nav>
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

    <!-- ✅ MODAL DE CONFIRMACIÓN PERSONALIZADO -->
    <ConfirmDeleteModal
      :isOpen="deleteConfirmModal.isOpen"
      :taskTitle="deleteConfirmModal.taskTitle"
      :loading="deleteConfirmModal.loading"
      @confirm="confirmDeleteTask"
      @cancel="cancelDeleteTask"
    />
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
import ConfirmDeleteModal from '@/components/modals/ConfirmDeleteModal.vue'

// ✅ IMPORTAR NOTIVUE
import { push } from 'notivue'

const route = useRoute()
const {
  tasks,
  loading,
  error,
  getTasks,
  getTodaysTasks,
  getUpcomingTasks,
  updateTask,
  toggleTaskStatus,
  deleteTask
} = useSupabase()

// ✅ ESTADO PARA EL MODAL DE CONFIRMACIÓN
const deleteConfirmModal = ref({
  isOpen: false,
  taskId: null,
  taskTitle: '',
  loading: false
})

// ✅ FILTROS CON VALORES POR DEFECTO PARA HOY
const filters = ref({
  status: '',
  priority: '',
  dueDate: 'today',
  search: '',
  sortBy: 'due_time',
  sortOrder: 'asc'
})

// ✅ PAGINACIÓN
const currentPage = ref(1)
const itemsPerPage = ref(10)

// ✅ INDICADOR SI ESTAMOS EN VISTA LIMITADA
const isLimitedView = computed(() => {
  return filters.value.dueDate === 'today' || filters.value.dueDate === 'upcoming'
})

// Update filters
const updateFilters = (newFilters) => {
  filters.value = { ...newFilters }
  resetPagination() // ✅ Reset paginación cuando cambian filtros
}

const clearFilters = () => {
  filters.value = {
    status: '',
    priority: '',
    dueDate: 'today',
    search: '',
    sortBy: 'due_time',
    sortOrder: 'asc'
  }
  resetPagination() // ✅ Reset paginación

  // ✅ NOTIFICACIÓN PARA LIMPIAR FILTROS
  push.info({
    title: 'Filtros limpiados',
    message: 'Se han restablecido los filtros por defecto'
  })
}

// ✅ FUNCIÓN MEJORADA PARA CARGAR TAREAS SEGÚN FILTROS
const loadTasksBasedOnFilters = async () => {
  try {
    console.log('🔄 Cargando tareas con filtros:', filters.value)

    // Usar métodos específicos para casos optimizados
    if (filters.value.dueDate === 'today') {
      console.log('📅 Cargando tareas de hoy (optimizado)')
      await getTodaysTasks(100) // ✅ Aumentar límite para paginación local
    } else if (filters.value.dueDate === 'upcoming') {
      console.log('🔮 Cargando tareas próximas (optimizado)')
      await getUpcomingTasks(100) // ✅ Aumentar límite para paginación local
    } else {
      console.log('📋 Cargando todas las tareas')
      await getTasks()
    }
  } catch (err) {
    console.error('❌ Error cargando tareas:', err)
    // ✅ NOTIFICACIÓN DE ERROR
    push.error({
      title: 'Error al cargar tareas',
      message: 'No se pudieron cargar las tareas. Inténtalo de nuevo.'
    })
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
    resetPagination() // ✅ Reset paginación cuando cambia fecha
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
      return false
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

// ✅ CÁLCULOS DE PAGINACIÓN
const totalPages = computed(() => {
  return Math.ceil(filteredTasks.value.length / itemsPerPage.value)
})

const startIndex = computed(() => {
  return (currentPage.value - 1) * itemsPerPage.value
})

const endIndex = computed(() => {
  return startIndex.value + itemsPerPage.value
})

// ✅ TAREAS PAGINADAS (las que se muestran en la página actual)
const paginatedTasks = computed(() => {
  return filteredTasks.value.slice(startIndex.value, endIndex.value)
})

// ✅ PÁGINAS VISIBLES EN EL PAGINADOR
const visiblePages = computed(() => {
  const pages = []
  const total = totalPages.value
  const current = currentPage.value

  if (total <= 7) {
    // Si hay 7 páginas o menos, mostrar todas
    for (let i = 1; i <= total; i++) {
      pages.push(i)
    }
  } else {
    // Lógica para mostrar páginas con elipsis
    if (current <= 4) {
      // Cerca del inicio
      for (let i = 1; i <= 5; i++) {
        pages.push(i)
      }
      pages.push('...')
      pages.push(total)
    } else if (current >= total - 3) {
      // Cerca del final
      pages.push(1)
      pages.push('...')
      for (let i = total - 4; i <= total; i++) {
        pages.push(i)
      }
    } else {
      // En el medio
      pages.push(1)
      pages.push('...')
      for (let i = current - 1; i <= current + 1; i++) {
        pages.push(i)
      }
      pages.push('...')
      pages.push(total)
    }
  }

  return pages
})

// ✅ FUNCIONES DE PAGINACIÓN
const goToPage = (page) => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page
  }
}

const resetPagination = () => {
  currentPage.value = 1
}

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

// ✅ MANEJO MEJORADO DE ELIMINACIÓN CON MODAL
const handleDeleteTask = async (taskId) => {
  const task = tasks.value.find(t => t.id === taskId)
  if (!task) {
    push.error({
      title: 'Error',
      message: 'Tarea no encontrada'
    })
    return
  }

  // Abrir modal de confirmación
  deleteConfirmModal.value = {
    isOpen: true,
    taskId: taskId,
    taskTitle: task.title,
    loading: false
  }
}

// ✅ CONFIRMAR ELIMINACIÓN
const confirmDeleteTask = async () => {
  deleteConfirmModal.value.loading = true

  try {
    const taskTitle = deleteConfirmModal.value.taskTitle
    console.log('🗑️ TaskContainer - Eliminando tarea:', deleteConfirmModal.value.taskId)

    await deleteTask(deleteConfirmModal.value.taskId)

    // Notificación de éxito
    push.success({
      title: 'Tarea eliminada',
      message: `"${taskTitle}" ha sido eliminada exitosamente`
    })

    console.log('✅ TaskContainer - Tarea eliminada exitosamente')
  } catch (err) {
    console.error('❌ TaskContainer - Error eliminando tarea:', err)

    // Notificación de error
    push.error({
      title: 'Error al eliminar',
      message: 'No se pudo eliminar la tarea. Inténtalo de nuevo.'
    })
  } finally {
    // Cerrar modal
    deleteConfirmModal.value = {
      isOpen: false,
      taskId: null,
      taskTitle: '',
      loading: false
    }
  }
}

// ✅ CANCELAR ELIMINACIÓN
const cancelDeleteTask = () => {
  deleteConfirmModal.value = {
    isOpen: false,
    taskId: null,
    taskTitle: '',
    loading: false
  }
}

// ✅ MANEJAR ACTUALIZACIÓN DE ESTADO - IGUAL QUE TaskDetailView
const handleUpdateStatus = async (taskId, newStatus) => {
  try {
    console.log('🔄 TaskContainer - Actualizando estado:', taskId, newStatus)

    const task = tasks.value.find(t => t.id === taskId)
    if (!task) {
      push.error({
        title: 'Error',
        message: 'Tarea no encontrada'
      })
      return
    }

    const oldStatus = task.status

    // ✅ EVITAR ACTUALIZACIÓN DOBLE - Solo actualizar si realmente cambió
    if (oldStatus === newStatus) {
      console.log('⚠️ TaskContainer - Estado ya es el mismo, ignorando:', newStatus)
      return
    }

    console.log('📊 TaskContainer - Cambiando estado:', { taskId, oldStatus, newStatus })

    // ✅ USAR updateTask EN LUGAR DE toggleTaskStatus (igual que TaskDetailView)
    await updateTask(taskId, { status: newStatus })

    // ✅ NOTIFICACIÓN DE ACTUALIZACIÓN DE ESTADO
    const statusLabels = {
      pending: 'Pendiente',
      'in-progress': 'En Progreso',
      'on-hold': 'En Pausa',
      completed: 'Completada',
      cancelled: 'Cancelada'
    }

    push.success({
      title: 'Estado actualizado',
      message: `"${task.title}" cambió a "${statusLabels[newStatus] || newStatus}"`
    })

    console.log('✅ TaskContainer - Estado actualizado exitosamente')
  } catch (err) {
    console.error('❌ TaskContainer - Error actualizando estado:', err)

    push.error({
      title: 'Error al actualizar',
      message: 'No se pudo actualizar el estado de la tarea'
    })

    // ✅ REVERTIR EL ESTADO LOCAL EN CASO DE ERROR
    // Esto forzará que el TaskCard sincronice con el estado original
    await loadTasksBasedOnFilters()
  }
}

const handleUpdateTask = async (taskData) => {
  try {
    console.log('🔄 TaskContainer - Actualizando tarea desde TaskCard:', taskData)
    await updateTask(taskData.id, taskData)

    // ✅ NOTIFICACIÓN DE ACTUALIZACIÓN DE TAREA
    push.success({
      title: 'Tarea actualizada',
      message: `"${taskData.title}" ha sido actualizada`
    })

    console.log('✅ TaskContainer - Tarea actualizada exitosamente')
  } catch (err) {
    console.error('❌ TaskContainer - Error actualizando tarea:', err)

    push.error({
      title: 'Error al actualizar',
      message: 'No se pudo actualizar la tarea'
    })
  }
}

onMounted(async () => {
  console.log('🔄 TaskContainer - Cargando tareas iniciales')
  await loadTasksBasedOnFilters()
})
</script>

<style lang="scss" scoped>
</style>
