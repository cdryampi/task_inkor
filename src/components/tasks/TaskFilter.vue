<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
    <div class="flex flex-wrap items-center gap-4">
      <!-- Status Filter -->
      <div class="flex items-center space-x-2">
        <label class="text-sm font-medium text-gray-700">Estado:</label>
        <select
          v-model="localFilters.status"
          @change="emitFilters"
          class="text-sm border-gray-300 rounded-md focus:border-primary-500 focus:ring-primary-500">
          <option value="">Todos</option>
          <option value="pending">Pendientes</option>
          <option value="in-progress">En Progreso</option>
          <option value="on-hold">En Pausa</option>
          <option value="completed">Completadas</option>
          <option value="cancelled">Canceladas</option>
        </select>
      </div>

      <!-- Priority Filter -->
      <div class="flex items-center space-x-2">
        <label class="text-sm font-medium text-gray-700">Prioridad:</label>
        <select
          v-model="localFilters.priority"
          @change="emitFilters"
          class="text-sm border-gray-300 rounded-md focus:border-primary-500 focus:ring-primary-500">
          <option value="">Todas</option>
          <option value="high">Alta</option>
          <option value="medium">Media</option>
          <option value="normal">Normal</option>
        </select>
      </div>

      <!-- Due Date Filter -->
      <div class="flex items-center space-x-2">
        <label class="text-sm font-medium text-gray-700">Vencimiento:</label>
        <select
          v-model="localFilters.dueDate"
          @change="emitFilters"
          class="text-sm border-gray-300 rounded-md focus:border-primary-500 focus:ring-primary-500">
          <!-- ✅ HOY COMO PRIMERA OPCIÓN Y POR DEFECTO -->
          <option value="today">Solo hoy</option>
          <option value="">Todas las fechas</option>
          <option value="overdue">Vencidas</option>
          <option value="tomorrow">Mañana</option>
          <option value="this-week">Esta semana</option>
          <option value="next-week">Próxima semana</option>
          <option value="upcoming">Próximas</option>
          <option value="no-date">Sin fecha</option>
        </select>
      </div>

      <!-- Search -->
      <div class="flex items-center space-x-2 flex-1 min-w-[200px]">
        <label class="text-sm font-medium text-gray-700">Buscar:</label>
        <div class="relative flex-1">
          <MagnifyingGlassIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            v-model="localFilters.search"
            @input="emitFilters"
            type="text"
            placeholder="Título o descripción..."
            class="pl-10 pr-4 py-2 text-sm border-gray-300 rounded-md focus:border-primary-500 focus:ring-primary-500 w-full">
        </div>
      </div>

      <!-- Sort -->
      <div class="flex items-center space-x-2">
        <label class="text-sm font-medium text-gray-700">Ordenar:</label>
        <select
          v-model="localFilters.sortBy"
          @change="emitFilters"
          class="text-sm border-gray-300 rounded-md focus:border-primary-500 focus:ring-primary-500">
          <option value="due_time">Hora vencimiento</option>
          <option value="priority">Prioridad</option>
          <option value="created_at">Fecha creación</option>
          <option value="due_date">Fecha vencimiento</option>
          <option value="title">Título</option>
          <option value="status">Estado</option>
        </select>
        <button
          @click="toggleSortOrder"
          class="p-1 text-gray-500 hover:text-gray-700 transition-colors">
          <ArrowUpIcon v-if="localFilters.sortOrder === 'asc'" class="w-4 h-4" />
          <ArrowDownIcon v-else class="w-4 h-4" />
        </button>
      </div>

      <!-- Clear Filters -->
      <button
        v-if="hasActiveFilters"
        @click="clearFilters"
        class="flex items-center space-x-1 text-gray-500 hover:text-red-600 px-2 py-1 rounded-md transition-colors text-sm">
        <XMarkIcon class="w-4 h-4" />
        <span>Limpiar</span>
      </button>
    </div>

    <!-- Active filters summary -->
    <div v-if="hasActiveFilters" class="mt-3 pt-3 border-t border-gray-100">
      <div class="flex flex-wrap items-center gap-2">
        <span class="text-xs text-gray-500">Filtros activos:</span>
        <span v-for="filter in activeFiltersSummary" :key="filter.key"
              class="inline-flex items-center px-2 py-1 rounded-full text-xs bg-primary-100 text-primary-700">
          {{ filter.label }}
        </span>
      </div>
    </div>

    <!-- ✅ INFORMACIÓN SOBRE EL FILTRO ACTUAL CON ICONOS HEROICONS -->
    <div class="mt-2 text-xs text-gray-500">
      <span v-if="localFilters.dueDate === 'today'" class="flex items-center space-x-1">
        <CalendarDaysIcon class="w-3 h-3" />
        <span>Mostrando solo tareas de hoy (máximo 10) ordenadas por hora</span>
      </span>
      <span v-else-if="localFilters.dueDate === 'upcoming'" class="flex items-center space-x-1">
        <ClockIcon class="w-3 h-3" />
        <span>Mostrando tareas próximas (máximo 10)</span>
      </span>
      <span v-else-if="localFilters.dueDate === ''" class="flex items-center space-x-1">
        <ClipboardDocumentListIcon class="w-3 h-3" />
        <span>Mostrando todas las tareas</span>
      </span>
      <span v-else-if="localFilters.dueDate === 'overdue'" class="flex items-center space-x-1">
        <ExclamationTriangleIcon class="w-3 h-3 text-red-500" />
        <span>Filtro aplicado: {{ getCurrentFilterLabel() }}</span>
      </span>
      <span v-else class="flex items-center space-x-1">
        <FunnelIcon class="w-3 h-3" />
        <span>Filtro aplicado: {{ getCurrentFilterLabel() }}</span>
      </span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import {
  MagnifyingGlassIcon,
  ArrowUpIcon,
  ArrowDownIcon,
  XMarkIcon,
  CalendarDaysIcon,
  ClockIcon,
  ClipboardDocumentListIcon,
  ExclamationTriangleIcon,
  FunnelIcon
} from '@heroicons/vue/24/outline'

const props = defineProps({
  filters: {
    type: Object,
    default: () => ({
      status: '',
      priority: '',
      dueDate: 'today', // ✅ VALOR POR DEFECTO
      search: '',
      sortBy: 'due_time', // ✅ ORDENAR POR HORA POR DEFECTO
      sortOrder: 'asc'
    })
  }
})

const emit = defineEmits(['update:filters'])

// ✅ ASEGURAR QUE LOCALFILTERS SIEMPRE INICIE CON 'today'
const localFilters = ref({
  status: '',
  priority: '',
  dueDate: 'today', // ✅ FORZAR VALOR POR DEFECTO
  search: '',
  sortBy: 'due_time',
  sortOrder: 'asc',
  ...props.filters // Sobrescribir con props si existen
})

// Watch for external filter changes
watch(() => props.filters, (newFilters) => {
  localFilters.value = {
    ...localFilters.value,
    ...newFilters
  }
}, { deep: true })

// ✅ COMPUTED PROPERTIES ACTUALIZADAS
const hasActiveFilters = computed(() => {
  return localFilters.value.status ||
         localFilters.value.priority ||
         localFilters.value.dueDate !== 'today' || // ✅ HOY ES EL ESTADO "NORMAL"
         localFilters.value.search ||
         localFilters.value.sortBy !== 'due_time' ||
         localFilters.value.sortOrder !== 'asc'
})

const activeFiltersSummary = computed(() => {
  const summary = []

  if (localFilters.value.status) {
    const statusLabels = {
      pending: 'Pendientes',
      'in-progress': 'En Progreso',
      'on-hold': 'En Pausa',
      completed: 'Completadas',
      cancelled: 'Canceladas'
    }
    summary.push({
      key: 'status',
      label: statusLabels[localFilters.value.status]
    })
  }

  if (localFilters.value.priority) {
    const priorityLabels = {
      high: 'Prioridad Alta',
      medium: 'Prioridad Media',
      normal: 'Prioridad Normal'
    }
    summary.push({
      key: 'priority',
      label: priorityLabels[localFilters.value.priority]
    })
  }

  // ✅ SOLO MOSTRAR FILTRO DE FECHA SI NO ES "HOY"
  if (localFilters.value.dueDate && localFilters.value.dueDate !== 'today') {
    const dueDateLabels = {
      overdue: 'Vencidas',
      today: 'Solo hoy',
      tomorrow: 'Mañana',
      'this-week': 'Esta semana',
      'next-week': 'Próxima semana',
      'upcoming': 'Próximas',
      'no-date': 'Sin fecha',
      '': 'Todas las fechas'
    }
    summary.push({
      key: 'dueDate',
      label: dueDateLabels[localFilters.value.dueDate] || 'Filtro de fecha'
    })
  }

  if (localFilters.value.search) {
    summary.push({
      key: 'search',
      label: `Buscar: "${localFilters.value.search}"`
    })
  }

  return summary
})

// ✅ FUNCIÓN PARA OBTENER ETIQUETA DEL FILTRO ACTUAL
const getCurrentFilterLabel = () => {
  const dueDateLabels = {
    overdue: 'Vencidas',
    today: 'Solo hoy',
    tomorrow: 'Mañana',
    'this-week': 'Esta semana',
    'next-week': 'Próxima semana',
    'upcoming': 'Próximas',
    'no-date': 'Sin fecha',
    '': 'Todas las fechas'
  }
  return dueDateLabels[localFilters.value.dueDate] || 'Desconocido'
}

// Methods
const emitFilters = () => {
  emit('update:filters', { ...localFilters.value })
}

const toggleSortOrder = () => {
  localFilters.value.sortOrder = localFilters.value.sortOrder === 'asc' ? 'desc' : 'asc'
  emitFilters()
}

const clearFilters = () => {
  localFilters.value = {
    status: '',
    priority: '',
    dueDate: 'today', // ✅ SIEMPRE RESETEAR A HOY
    search: '',
    sortBy: 'due_time',
    sortOrder: 'asc'
  }
  emitFilters()
}
</script>
