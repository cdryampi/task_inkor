<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center mb-6 space-y-4 sm:space-y-0">
      <h1 class="text-2xl font-bold text-primary-800 flex items-center space-x-2">
        <CalendarDaysIcon class="w-7 h-7" />
        <span>Calendario de Tareas</span>
      </h1>

      <div class="flex space-x-2">
        <button
          @click="goToToday"
          class="px-3 py-2 bg-accent text-white rounded-lg hover:bg-accent-light transition-colors font-medium">
          Hoy
        </button>
        <button
          @click="viewMode = 'month'"
          :class="viewMode === 'month' ? activeButtonClass : inactiveButtonClass">
          Mes
        </button>
        <button
          @click="viewMode = 'week'"
          :class="viewMode === 'week' ? activeButtonClass : inactiveButtonClass">
          Semana
        </button>
      </div>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="text-center py-8">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      <p class="mt-2 text-primary-600">Cargando calendario...</p>
    </div>

    <!-- Error state -->
    <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
      {{ error }}
    </div>

    <!-- Calendario Principal -->
    <div v-if="!loading" class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <VCalendar
        ref="calendar"
        :attributes="calendarAttributes"
        class="custom-calendar w-full"
        expanded
        borderless
        @dayclick="handleDayClick"
        @update:page="handlePageChange">

        <!-- Slot personalizado para días -->
        <template #day-content="{ day }">
          <div class="relative w-full h-full min-h-[80px] p-1 cursor-pointer hover:bg-primary-50 transition-colors rounded">
            <!-- Número del día -->
            <div class="flex justify-between items-start">
              <span class="text-sm font-medium text-gray-800">{{ day.day }}</span>
              <div v-if="isToday(day)" class="w-2 h-2 bg-accent rounded-full animate-pulse"></div>
            </div>

            <!-- Tareas del día con íconos de prioridad -->
            <div v-if="getTasksForDay(day).length > 0" class="mt-1 space-y-1">
              <div
                v-for="(task, index) in getTasksForDay(day).slice(0, 3)"
                :key="task.id"
                :class="getTaskBarClass(task)"
                class="text-xs px-2 py-1 rounded text-white truncate font-medium shadow-sm flex items-center space-x-1 relative overflow-hidden">

                <!-- Ícono de prioridad en las barras del calendario -->
                <component
                  :is="getPriorityIcon(task.priority || 'normal')"
                  class="w-3 h-3 flex-shrink-0"
                  :class="{
                    'text-red-200': task.priority === 'high',
                    'text-yellow-200': task.priority === 'medium',
                    'text-gray-300': !task.priority || task.priority === 'normal'
                  }" />

                <span class="truncate">{{ task.title }}</span>

                <!-- Efecto de brillo para tareas urgentes -->
                <div
                  v-if="task.priority === 'high'"
                  class="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-20 animate-shimmer"></div>
              </div>

              <!-- Mostrar +X más si hay más tareas -->
              <div
                v-if="getTasksForDay(day).length > 3"
                class="text-xs text-gray-500 pl-2 font-medium flex items-center space-x-1">
                <ChevronUpIcon class="w-3 h-3" />
                <span>+{{ getTasksForDay(day).length - 3 }} más</span>
              </div>
            </div>
          </div>
        </template>
      </VCalendar>
    </div>

    <!-- Panel lateral con tareas del día seleccionado MEJORADO -->
    <div v-if="selectedDate && !loading" class="mt-6 bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="p-4 border-b border-gray-200 bg-gradient-to-r from-primary-50 to-primary-100">
        <h3 class="text-lg font-semibold text-primary-800 flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <CalendarDaysIcon class="w-5 h-5" />
            <span>{{ formatSelectedDate }}</span>
          </div>
          <div class="flex items-center space-x-2">
            <!-- Distribución de prioridades -->
            <div v-if="selectedDayTasks.length > 0" class="flex items-center space-x-1 text-xs">
              <div v-if="selectedDayTasks.filter(t => t.priority === 'high').length > 0"
                   class="flex items-center space-x-1 bg-red-100 text-red-700 px-2 py-1 rounded-full">
                <FireIconSolid class="w-3 h-3" />
                <span>{{ selectedDayTasks.filter(t => t.priority === 'high').length }}</span>
              </div>
              <div v-if="selectedDayTasks.filter(t => t.priority === 'medium').length > 0"
                   class="flex items-center space-x-1 bg-yellow-100 text-yellow-700 px-2 py-1 rounded-full">
                <ExclamationTriangleIconSolid class="w-3 h-3" />
                <span>{{ selectedDayTasks.filter(t => t.priority === 'medium').length }}</span>
              </div>
            </div>
            <span class="text-sm font-medium bg-primary-200 text-primary-800 px-2 py-1 rounded-full">
              {{ selectedDayTasks.length }} tarea{{ selectedDayTasks.length === 1 ? '' : 's' }}
            </span>
          </div>
        </h3>
      </div>

      <div class="p-4">
        <!-- Tareas del día MEJORADAS -->
        <div v-if="selectedDayTasks.length > 0" class="space-y-3">
          <div
            v-for="task in selectedDayTasks"
            :key="task.id"
            class="flex items-center justify-between p-4 rounded-lg border transition-all hover:shadow-md relative"
            :class="task.status === 'completed' ?
              'bg-green-50 border-green-200' :
              'bg-gray-50 border-gray-200 hover:bg-gray-100'">

            <!-- Borde lateral de prioridad -->
            <div
              class="absolute left-0 top-0 bottom-0 w-1 rounded-l-lg"
              :class="{
                'bg-gradient-to-b from-red-500 to-red-600': task.priority === 'high',
                'bg-gradient-to-b from-yellow-500 to-yellow-600': task.priority === 'medium',
                'bg-gradient-to-b from-gray-400 to-gray-500': !task.priority || task.priority === 'normal'
              }"></div>

            <div class="flex items-center space-x-3">
              <button
                @click="toggleTaskStatus(task.id, task.status)"
                class="flex-shrink-0 transition-colors">
                <CheckCircleIcon
                  :class="task.status === 'completed' ?
                    'text-green-500 hover:text-green-600' :
                    'text-gray-400 hover:text-primary-500'"
                  class="w-6 h-6" />
              </button>

              <div class="flex-1">
                <div class="flex items-center space-x-2 mb-1">
                  <h4
                    :class="task.status === 'completed' ?
                      'line-through text-gray-500' :
                      'text-gray-800'"
                    class="font-medium">
                    {{ task.title }}
                  </h4>

                  <!-- Ícono de prioridad grande y visible -->
                  <div v-if="task.priority && task.priority !== 'normal'"
                       class="flex items-center space-x-1"
                       :class="{
                         'animate-pulse': task.priority === 'high'
                       }">
                    <component
                      :is="getPriorityIcon(task.priority)"
                      class="w-4 h-4"
                      :class="{
                        'text-red-500': task.priority === 'high',
                        'text-yellow-500': task.priority === 'medium'
                      }" />
                  </div>
                </div>

                <p v-if="task.description" class="text-sm text-gray-600 mt-1">
                  {{ task.description }}
                </p>

                <div class="flex items-center space-x-2 mt-2">
                  <!-- Badge de prioridad mejorado -->
                  <div class="flex items-center space-x-1">
                    <span class="text-xs px-2 py-1 rounded-full font-medium flex items-center space-x-1"
                          :class="getPriorityClass(task.priority || 'normal')">
                      <component
                        :is="getPriorityIcon(task.priority || 'normal')"
                        class="w-3 h-3" />
                      <span>{{ getPriorityLabel(task.priority || 'normal') }}</span>
                    </span>
                  </div>

                  <!-- Hora con mejor styling -->
                  <span v-if="task.due_time" class="text-xs text-gray-500 flex items-center space-x-1 bg-gray-100 px-2 py-1 rounded-full">
                    <ClockIcon class="w-3 h-3" />
                    <span class="font-medium">{{ formatTime(task.due_time) }}</span>
                  </span>
                </div>
              </div>
            </div>

            <div class="flex space-x-2">
              <button
                @click="editTask(task)"
                class="p-2 text-primary-500 hover:text-primary-600 hover:bg-primary-100 rounded transition-colors">
                <PencilIcon class="w-4 h-4" />
              </button>
              <button
                @click="confirmDeleteTask(task)"
                class="p-2 text-red-500 hover:text-red-600 hover:bg-red-100 rounded transition-colors">
                <TrashIcon class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        <!-- Empty state -->
        <div v-else class="text-center py-12">
          <CalendarDaysIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <p class="text-gray-500 mb-4">No hay tareas programadas para este día</p>
          <button
            @click="createTaskForDate"
            class="inline-flex items-center space-x-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors font-medium shadow-sm">
            <PlusCircleIcon class="w-4 h-4" />
            <span>Programar Tarea</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Estadísticas rápidas -->
    <div v-if="!loading" class="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4">
      <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-primary-100 rounded-lg">
            <ClipboardDocumentListIcon class="w-5 h-5 text-primary-600" />
          </div>
          <div>
            <p class="text-sm text-gray-600">Total Tareas</p>
            <p class="text-lg font-semibold text-gray-800">{{ tasks.length }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-yellow-100 rounded-lg">
            <ClockIcon class="w-5 h-5 text-yellow-600" />
          </div>
          <div>
            <p class="text-sm text-gray-600">Pendientes</p>
            <p class="text-lg font-semibold text-gray-800">{{ pendingTasks.length }}</p>
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
            <p class="text-lg font-semibold text-gray-800">{{ completedTasks.length }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-accent-light rounded-lg">
            <CalendarDaysIcon class="w-5 h-5 text-accent" />
          </div>
          <div>
            <p class="text-sm text-gray-600">Este mes</p>
            <p class="text-lg font-semibold text-gray-800">{{ thisMonthTasks.length }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de nueva tarea -->
    <NewTaskModal
      :isOpen="isModalOpen"
      :loading="creatingTask"
      :presetDate="selectedDateForTask"
      @close="closeModal"
      @submit="handleCreateTask" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import {
  CalendarDaysIcon,
  CheckCircleIcon,
  PlusCircleIcon,
  PencilIcon,
  TrashIcon,
  ClipboardDocumentListIcon,
  ClockIcon,
  ChevronUpIcon,
  MinusIcon
} from '@heroicons/vue/24/outline'
import {
  ExclamationTriangleIcon as ExclamationTriangleIconSolid,
  FireIcon as FireIconSolid
} from '@heroicons/vue/24/solid'
import { useSupabase } from '@/hooks/supabase'
import { useNewTaskModal } from '@/composables/useNewTaskModal'
import NewTaskModal from '@/components/modals/NewTaskModal.vue'

const {
  tasks,
  pendingTasks,
  completedTasks,
  loading,
  error,
  getTasks,
  createTask,
  toggleTaskStatus,
  deleteTask
} = useSupabase()

const { isModalOpen, openModal, closeModal } = useNewTaskModal()

// Estado reactivo
const viewMode = ref('month')
const selectedDate = ref(null)
const calendar = ref(null)
const creatingTask = ref(false)
const selectedDateForTask = ref(null)

// Clases CSS
const activeButtonClass = 'px-3 py-2 bg-primary-500 text-white rounded-lg font-medium shadow-sm'
const inactiveButtonClass = 'px-3 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors'

// Computadas
const thisMonthTasks = computed(() => {
  const currentMonth = new Date().getMonth()
  const currentYear = new Date().getFullYear()

  return tasks.value.filter(task => {
    if (!task.due_date) return false
    const taskDate = new Date(task.due_date)
    return taskDate.getMonth() === currentMonth && taskDate.getFullYear() === currentYear
  })
})

// Atributos del calendario
const calendarAttributes = computed(() => {
  const attributes = []

  // Agrupar tareas por fecha
  const tasksByDate = {}
  tasks.value.forEach(task => {
    if (!task.due_date) return

    const dateKey = task.due_date.split('T')[0]
    if (!tasksByDate[dateKey]) {
      tasksByDate[dateKey] = []
    }
    tasksByDate[dateKey].push(task)
  })

  // Crear atributos para cada fecha con tareas
  Object.entries(tasksByDate).forEach(([date, dayTasks]) => {
    const completedCount = dayTasks.filter(t => t.status === 'completed').length
    const pendingCount = dayTasks.filter(t => t.status === 'pending').length
    const hasHighPriority = dayTasks.some(t => t.priority === 'high')

    // Determinar color del highlight
    let highlightColor = '#f3f4f6' // gray-100
    if (pendingCount > 0 && hasHighPriority) {
      highlightColor = '#fef2f2' // red-50
    } else if (pendingCount > 0) {
      highlightColor = '#eff6ff' // blue-50
    } else if (completedCount > 0) {
      highlightColor = '#f0fdf4' // green-50
    }

    attributes.push({
      key: `tasks-${date}`,
      dates: new Date(date),
      highlight: {
        color: highlightColor,
        fillMode: 'light'
      },
      popover: {
        label: `${dayTasks.length} tarea${dayTasks.length === 1 ? '' : 's'}`,
        visibility: 'hover'
      }
    })
  })

  return attributes
})

// Obtener tareas para un día específico
const getTasksForDay = (day) => {
  const dateStr = day.id.split('T')[0]
  return tasks.value.filter(task =>
    task.due_date && task.due_date.split('T')[0] === dateStr
  )
}

// Tareas del día seleccionado
const selectedDayTasks = computed(() => {
  if (!selectedDate.value) return []
  return getTasksForDay(selectedDate.value).sort((a, b) => {
    // Ordenar por estado (pendientes primero) y luego por prioridad
    if (a.status !== b.status) {
      return a.status === 'pending' ? -1 : 1
    }

    const priorityOrder = { high: 3, medium: 2, normal: 1 }
    return (priorityOrder[b.priority] || 1) - (priorityOrder[a.priority] || 1)
  })
})

// Formato de fecha seleccionada
const formatSelectedDate = computed(() => {
  if (!selectedDate.value) return ''
  return new Intl.DateTimeFormat('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }).format(selectedDate.value.date)
})

// Funciones de prioridad
const getPriorityClass = (priority) => {
  switch (priority) {
    case 'high':
      return 'bg-gradient-to-r from-red-100 to-red-200 text-red-800 border border-red-300 shadow-sm'
    case 'medium':
      return 'bg-gradient-to-r from-yellow-100 to-yellow-200 text-yellow-800 border border-yellow-300 shadow-sm'
    default:
      return 'bg-gradient-to-r from-gray-100 to-gray-200 text-gray-700 border border-gray-300'
  }
}

const getPriorityIcon = (priority) => {
  switch (priority) {
    case 'high': return FireIconSolid
    case 'medium': return ExclamationTriangleIconSolid
    default: return MinusIcon
  }
}

const getPriorityLabel = (priority) => {
  switch (priority) {
    case 'high': return 'Urgente'
    case 'medium': return 'Media'
    default: return 'Normal'
  }
}

const getTaskBarClass = (task) => {
  if (task.status === 'completed') return 'bg-gradient-to-r from-green-500 to-green-600'

  switch (task.priority) {
    case 'high': return 'bg-gradient-to-r from-red-500 to-red-600 shadow-lg'
    case 'medium': return 'bg-gradient-to-r from-yellow-500 to-yellow-600 shadow-md'
    default: return 'bg-gradient-to-r from-primary-500 to-primary-600'
  }
}

// Métodos principales
const handleDayClick = (day) => {
  selectedDate.value = day
  console.log('📅 Día seleccionado:', day.id, getTasksForDay(day))
}

const handlePageChange = (page) => {
  console.log('📅 Página cambiada:', page)
}

const isToday = (day) => {
  const today = new Date()
  return day.date.toDateString() === today.toDateString()
}

const formatTime = (timeStr) => {
  if (!timeStr) return ''
  return new Date(`2000-01-01T${timeStr}`).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const goToToday = () => {
  if (calendar.value) {
    calendar.value.move(new Date())
  }
  // Seleccionar el día de hoy
  selectedDate.value = {
    id: new Date().toISOString(),
    date: new Date(),
    day: new Date().getDate()
  }
}

const createTaskForDate = () => {
  console.log('➕ Crear tarea para:', selectedDate.value?.date)
  // Preparar la fecha seleccionada para el modal
  selectedDateForTask.value = selectedDate.value?.date
  openModal()
}

// Handle create task desde el modal
const handleCreateTask = async (taskData) => {
  creatingTask.value = true
  try {
    // Si hay fecha preseleccionada, añadirla a los datos
    if (selectedDateForTask.value) {
      const dateString = selectedDateForTask.value.toISOString().split('T')[0]
      taskData.due_date = dateString
      console.log('📅 Fecha preseleccionada aplicada:', dateString)
    }

    console.log('🚀 Enviando a createTask:', taskData)
    await createTask(taskData)

    closeModal()
    selectedDateForTask.value = null
    console.log('✅ Tarea creada exitosamente desde calendario')
  } catch (err) {
    console.error('❌ Error creando tarea:', err)
  } finally {
    creatingTask.value = false
  }
}

const editTask = (task) => {
  console.log('✏️ Editar tarea:', task)
  // TODO: Implementar modal de edición
}

const confirmDeleteTask = async (task) => {
  if (confirm(`¿Estás seguro de que quieres eliminar "${task.title}"?`)) {
    try {
      await deleteTask(task.id)
      console.log('🗑️ Tarea eliminada exitosamente')
    } catch (err) {
      console.error('❌ Error eliminando tarea:', err)
    }
  }
}

// Cargar tareas al montar
onMounted(async () => {
  await getTasks()
  // Seleccionar el día de hoy por defecto
  goToToday()
})
</script>

<style scoped>
.custom-calendar {
  --vc-color-primary: #10b981;
  --vc-color-primary-light: #d1fae5;
  --vc-weekday-color: #525252;
  --vc-nav-arrow-color: #059669;
}

/* Animación de brillo para tareas urgentes */
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.animate-shimmer {
  animation: shimmer 2s infinite;
}

/* Mejorar la apariencia de los días del calendario */
:deep(.vc-day) {
  border: 1px solid #e5e5e5;
  min-height: 100px;
  transition: all 0.2s ease;
}

:deep(.vc-day:hover) {
  background-color: #ecfdf5;
  border-color: #10b981;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(16, 185, 129, 0.1);
}

:deep(.vc-day.selected) {
  background-color: #d1fae5;
  border-color: #10b981;
  box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
}

/* Estilos adicionales para mejor UX */
:deep(.vc-container) {
  border: none !important;
}

:deep(.vc-header) {
  padding: 2.5rem;
  margin-top: 0rem !important;
}

:deep(.vc-title) {
  color: #059669 !important;
  font-weight: 600;
  font-size: 1.5rem;
  text-align: center;
  font-weight: bold;
  text-transform: uppercase;
}

:deep(.vc-nav-arrow) {
  color: #059669;
  border-radius: 0.5rem;
  padding: 0.5rem;
  transition: all 0.2s;
}

:deep(.vc-nav-arrow:hover) {
  background-color: #a7f3d0;
  transform: scale(1.1);
}

:deep(.vc-weeks) {
  padding: 0;
}

:deep(.vc-weekday) {
  color: #525252;
  font-weight: 600;
  padding: 0.75rem 0;
  background-color: #e5e5e5;
}
</style>
