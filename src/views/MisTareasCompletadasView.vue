<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-primary-800">Mis Tareas Completadas</h1>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="text-center py-8">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      <p class="mt-2 text-primary-600">Cargando tareas completadas...</p>
    </div>

    <!-- Error state -->
    <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
      {{ error }}
    </div>

    <!-- Barra de resumen -->
    <div v-if="!loading" class="mb-6 grid grid-cols-1 md:grid-cols-2 gap-4">
      <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-green-100 rounded-lg">
            <CheckCircleIcon class="w-5 h-5 text-green-600" />
          </div>
          <div>
            <p class="text-sm text-gray-600">Total Completadas</p>
            <p class="text-lg font-semibold text-gray-800">{{ completedTasks.length }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-blue-100 rounded-lg">
            <CalendarDaysIcon class="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <p class="text-sm text-gray-600">Completadas Hoy</p>
            <p class="text-lg font-semibold text-gray-800">{{ todayCompletedCount }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Filtros simplificados para tareas completadas -->
    <div v-if="!loading && completedTasks.length > 0" class="mb-6 bg-white p-4 rounded-lg shadow-sm border border-gray-200">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <!-- Búsqueda -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Buscar</label>
          <input
            v-model="searchTerm"
            type="text"
            placeholder="Buscar por título o descripción..."
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            @input="resetPagination"
          />
        </div>

        <!-- Prioridad -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Prioridad</label>
          <select
            v-model="priorityFilter"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            @change="resetPagination"
          >
            <option value="">Todas las prioridades</option>
            <option value="high">Alta</option>
            <option value="medium">Media</option>
            <option value="normal">Normal</option>
          </select>
        </div>

        <!-- Ordenar por -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Ordenar por</label>
          <select
            v-model="sortBy"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            @change="resetPagination"
          >
            <option value="updated_at">Fecha de finalización</option>
            <option value="title">Título</option>
            <option value="priority">Prioridad</option>
            <option value="created_at">Fecha de creación</option>
          </select>
        </div>

        <!-- Tareas por página -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Por página</label>
          <select
            v-model="itemsPerPage"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            @change="resetPagination"
          >
            <option :value="5">5 tareas</option>
            <option :value="10">10 tareas</option>
            <option :value="20">20 tareas</option>
            <option :value="50">50 tareas</option>
          </select>
        </div>
      </div>

      <!-- Botón limpiar filtros -->
      <div v-if="hasActiveFilters" class="mt-4 flex justify-end">
        <button
          @click="clearFilters"
          class="text-sm text-primary-600 hover:text-primary-700"
        >
          Limpiar filtros
        </button>
      </div>
    </div>

    <!-- Results count y paginación info -->
    <div v-if="!loading && filteredTasks.length > 0" class="mb-4 flex justify-between items-center">
      <div>
        <p class="text-sm text-gray-600">
          Mostrando {{ startIndex + 1 }}-{{ Math.min(endIndex, filteredTasks.length) }} de {{ filteredTasks.length }} tareas completadas
          <span v-if="filteredTasks.length !== completedTasks.length">
            ({{ completedTasks.length }} total)
          </span>
        </p>
      </div>

      <!-- Mini paginador superior (solo si hay muchas páginas) -->
      <div v-if="totalPages > 5" class="text-sm text-gray-500">
        Página {{ currentPage }} de {{ totalPages }}
      </div>
    </div>

    <!-- Tasks list -->
    <div v-if="!loading && paginatedTasks.length > 0" class="space-y-4">
      <div
        v-for="task in paginatedTasks"
        :key="task.id"
        class="bg-white p-4 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow"
      >
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <!-- Header de la tarea con estado completado -->
            <div class="flex items-center space-x-2 mb-2">
              <CheckCircleIcon class="w-5 h-5 text-green-500" />
              <h3 class="text-lg font-semibold text-gray-800">{{ task.title }}</h3>
              <span
                :class="getPriorityBadgeClass(task.priority)"
                class="px-2 py-1 text-xs font-medium rounded-full"
              >
                {{ getPriorityLabel(task.priority) }}
              </span>
            </div>

            <!-- Descripción -->
            <p v-if="task.description" class="text-gray-600 mb-3">
              {{ task.description }}
            </p>

            <!-- Metadatos -->
            <div class="flex flex-wrap items-center space-x-4 text-sm text-gray-500">
              <span v-if="task.due_date" class="flex items-center space-x-1">
                <CalendarDaysIcon class="w-4 h-4" />
                <span>Vencía: {{ formatDate(task.due_date) }}</span>
              </span>
              <span class="flex items-center space-x-1">
                <ClockIcon class="w-4 h-4" />
                <span>Completada: {{ formatDate(task.updated_at) }}</span>
              </span>
            </div>
          </div>

          <!-- Botón para cambiar estado -->
          <div class="ml-4">
            <button
              @click="changeTaskStatus(task)"
              class="px-3 py-1 text-sm bg-primary-100 text-primary-700 rounded-lg hover:bg-primary-200 transition-colors"
              title="Cambiar estado de la tarea"
            >
              Cambiar Estado
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Paginador principal -->
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
    <div v-if="!loading && completedTasks.length === 0" class="text-center py-12">
      <CheckCircleIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <p class="text-gray-500 mb-4">No tienes tareas completadas aún</p>
      <p class="text-sm text-gray-400">
        Las tareas que completes aparecerán aquí
      </p>
    </div>

    <!-- No results state -->
    <div v-if="!loading && filteredTasks.length === 0 && completedTasks.length > 0" class="text-center py-12">
      <MagnifyingGlassIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <p class="text-gray-500 mb-4">No se encontraron tareas completadas con los filtros aplicados</p>
      <button
        @click="clearFilters"
        class="text-primary-600 hover:text-primary-700 text-sm">
        Limpiar filtros
      </button>
    </div>

    <!-- Modal para cambiar estado -->
    <div v-if="statusModal.isOpen" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg p-6 w-full max-w-md mx-4">
        <h3 class="text-lg font-semibold text-gray-800 mb-4">
          Cambiar Estado de Tarea
        </h3>

        <p class="text-gray-600 mb-4">
          "{{ statusModal.taskTitle }}"
        </p>

        <div class="space-y-2 mb-6">
          <label class="block text-sm font-medium text-gray-700">Nuevo estado:</label>
          <select
            v-model="statusModal.newStatus"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          >
            <option value="pending">Pendiente</option>
            <option value="in-progress">En Progreso</option>
            <option value="on-hold">En Pausa</option>
            <option value="completed">Completada</option>
            <option value="cancelled">Cancelada</option>
          </select>
        </div>

        <div class="flex space-x-3">
          <button
            @click="confirmStatusChange"
            :disabled="statusModal.loading"
            class="flex-1 bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 disabled:opacity-50"
          >
            <span v-if="!statusModal.loading">Confirmar</span>
            <span v-else>Actualizando...</span>
          </button>

          <button
            @click="cancelStatusChange"
            :disabled="statusModal.loading"
            class="flex-1 bg-gray-300 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-400 disabled:opacity-50"
          >
            Cancelar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import {
  CheckCircleIcon,
  CalendarDaysIcon,
  ClockIcon,
  MagnifyingGlassIcon
} from '@heroicons/vue/24/outline'
import { useSupabase } from '@/hooks/supabase'
import { push } from 'notivue'

const {
  tasks,
  loading,
  error,
  getTasks,
  toggleTaskStatus
} = useSupabase()

// Filtros
const searchTerm = ref('')
const priorityFilter = ref('')
const sortBy = ref('updated_at')

// Paginación
const currentPage = ref(1)
const itemsPerPage = ref(10)

// Modal para cambiar estado
const statusModal = ref({
  isOpen: false,
  taskId: null,
  taskTitle: '',
  newStatus: 'pending',
  loading: false
})

// Computed para tareas completadas
const completedTasks = computed(() => {
  return tasks.value.filter(task => task.status === 'completed')
})

// Tareas completadas hoy
const todayCompletedCount = computed(() => {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  return completedTasks.value.filter(task => {
    const updatedDate = new Date(task.updated_at)
    updatedDate.setHours(0, 0, 0, 0)
    return updatedDate.getTime() === today.getTime()
  }).length
})

// Tareas filtradas
const filteredTasks = computed(() => {
  let filtered = [...completedTasks.value]

  // Filtro de búsqueda
  if (searchTerm.value) {
    const search = searchTerm.value.toLowerCase()
    filtered = filtered.filter(task =>
      task.title.toLowerCase().includes(search) ||
      (task.description && task.description.toLowerCase().includes(search))
    )
  }

  // Filtro por prioridad
  if (priorityFilter.value) {
    filtered = filtered.filter(task => task.priority === priorityFilter.value)
  }

  // Ordenamiento
  filtered.sort((a, b) => {
    let comparison = 0

    switch (sortBy.value) {
      case 'title':
        comparison = a.title.localeCompare(b.title)
        break
      case 'priority':
        const priorityOrder = { high: 3, medium: 2, normal: 1 }
        comparison = (priorityOrder[b.priority] || 1) - (priorityOrder[a.priority] || 1)
        break
      case 'created_at':
        comparison = new Date(a.created_at) - new Date(b.created_at)
        break
      case 'updated_at':
      default:
        comparison = new Date(b.updated_at) - new Date(a.updated_at) // Más recientes primero
        break
    }

    return comparison
  })

  return filtered
})

// Cálculos de paginación
const totalPages = computed(() => {
  return Math.ceil(filteredTasks.value.length / itemsPerPage.value)
})

const startIndex = computed(() => {
  return (currentPage.value - 1) * itemsPerPage.value
})

const endIndex = computed(() => {
  return startIndex.value + itemsPerPage.value
})

// Tareas paginadas (las que se muestran en la página actual)
const paginatedTasks = computed(() => {
  return filteredTasks.value.slice(startIndex.value, endIndex.value)
})

// Páginas visibles en el paginador
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

// Verificar si hay filtros activos
const hasActiveFilters = computed(() => {
  return searchTerm.value || priorityFilter.value
})

// Funciones de paginación
const goToPage = (page) => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page
  }
}

const resetPagination = () => {
  currentPage.value = 1
}

// Limpiar filtros
const clearFilters = () => {
  searchTerm.value = ''
  priorityFilter.value = ''
  sortBy.value = 'updated_at'
  resetPagination()

  push.info({
    title: 'Filtros limpiados',
    message: 'Se han restablecido los filtros'
  })
}

// Abrir modal para cambiar estado
const changeTaskStatus = (task) => {
  statusModal.value = {
    isOpen: true,
    taskId: task.id,
    taskTitle: task.title,
    newStatus: 'pending', // Por defecto cambiar a pendiente
    loading: false
  }
}

// Confirmar cambio de estado
const confirmStatusChange = async () => {
  statusModal.value.loading = true

  try {
    await toggleTaskStatus(statusModal.value.taskId, statusModal.value.newStatus)

    const statusLabels = {
      pending: 'Pendiente',
      'in-progress': 'En Progreso',
      'on-hold': 'En Pausa',
      completed: 'Completada',
      cancelled: 'Cancelada'
    }

    push.success({
      title: 'Estado actualizado',
      message: `La tarea ahora está "${statusLabels[statusModal.value.newStatus]}"`
    })

    cancelStatusChange()
  } catch (err) {
    console.error('Error actualizando estado:', err)
    push.error({
      title: 'Error',
      message: 'No se pudo actualizar el estado de la tarea'
    })
  } finally {
    statusModal.value.loading = false
  }
}

// Cancelar cambio de estado
const cancelStatusChange = () => {
  statusModal.value = {
    isOpen: false,
    taskId: null,
    taskTitle: '',
    newStatus: 'pending',
    loading: false
  }
}

// Helpers para formateo
const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getPriorityLabel = (priority) => {
  const labels = {
    high: 'Alta',
    medium: 'Media',
    normal: 'Normal'
  }
  return labels[priority] || 'Normal'
}

const getPriorityBadgeClass = (priority) => {
  const classes = {
    high: 'bg-red-100 text-red-800',
    medium: 'bg-yellow-100 text-yellow-800',
    normal: 'bg-green-100 text-green-800'
  }
  return classes[priority] || classes.normal
}

onMounted(async () => {
  console.log('🔄 Cargando todas las tareas para filtrar completadas')
  await getTasks()
})
</script>

<style lang="scss" scoped>
</style>
