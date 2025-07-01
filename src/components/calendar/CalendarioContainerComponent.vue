<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <CalendarHeader
      :view-mode="viewMode"
      @go-to-today="goToToday"
      @update:view-mode="viewMode = $event"
    />

    <!-- Filtro de tareas -->
    <TaskFilter
      v-if="!loading"
      :filters="filters"
      @update:filters="updateFilters"
      class="mb-6"
    />

    <!-- Loading state -->
    <div v-if="loading" class="text-center py-8">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      <p class="mt-2 text-primary-600">Cargando calendario...</p>
    </div>

    <!-- Error state -->
    <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
      {{ error }}
    </div>

    <!-- Banner de filtros -->
    <CalendarFilterBanner
      v-if="!loading"
      :has-active-filters="hasActiveFilters"
      :active-filter-description="activeFilterDescription"
      :displayed-tasks-count="displayedTasksCount"
      :all-tasks-count="allTasksCount"
      :day-filter-active="dayFilterActive"
      @clear-day-filter="clearDayFilter"
      @clear-all-filters="clearAllFilters"
    />

    <!-- Calendario Principal -->
    <div v-if="!loading" class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <VCalendar
        ref="calendar"
        :attributes="calendarAttributes"
        class="custom-calendar w-full"
        expanded
        borderless
        @dayclick="handleVCalendarDayClick"
        @update:page="handlePageChange">

        <!-- ✅ SLOT CON EVENTOS PERSONALIZADOS -->
        <template #day-content="{ day }">
          <CalendarDay
            :day="day"
            :all-tasks="getTasksForDay(day)"
            :display-tasks="getDisplayTasksForDay(day)"
            :is-today="isToday(day)"
            :is-selected="isSelectedDay(day)"
            :is-filtered="isDayFiltered(day)"
            @day-click="handleDaySelection"
            @filter-by-day="handleFilterByDay"
          />
        </template>
      </VCalendar>
    </div>

    <!-- Panel lateral -->
    <TaskSidebar
      v-if="!loading"
      :selected-date="selectedDate"
      :tasks="selectedDayTasks"
      :is-day-filtered="selectedDate ? isDayFiltered(selectedDate) : false"
      @edit-task="handleEditTask"
      @delete-task="handleDeleteTask"
      @update-status="handleUpdateStatus"
      @create-task="createTaskForDate"
    />

    <!-- Estadísticas -->
    <CalendarStats
      v-if="!loading"
      :displayed-tasks-count="displayedTasksCount"
      :pending-tasks-count="pendingTasksCount"
      :completed-tasks-count="completedTasksCount"
      :this-month-tasks-count="thisMonthTasksCount"
      :day-filter-active="dayFilterActive"
    />

    <!-- Modales -->
    <NewTaskModal
      :isOpen="isModalOpen"
      :loading="creatingTask"
      :presetDate="selectedDateForTask"
      :editTask="editingTask"
      @close="handleCloseModal"
      @submit="handleCreateTask"
      @update="handleUpdateTask" />

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
import { ref, computed, onMounted, watch } from 'vue'
import { useSupabase } from '@/hooks/supabase'
import { useNewTaskModal } from '@/composables/useNewTaskModal'
import { useCalendarFilters } from '@/composables/useCalendarFilters'
import { push } from 'notivue'

// Componentes
import CalendarHeader from './CalendarHeader.vue'
import CalendarFilterBanner from './CalendarFilterBanner.vue'
import CalendarDay from './CalendarDay.vue'
import TaskSidebar from './TaskSidebar.vue'
import CalendarStats from './CalendarStats.vue'
import TaskFilter from '@/components/tasks/TaskFilter.vue'
import NewTaskModal from '@/components/modals/NewTaskModal.vue'
import ConfirmDeleteModal from '@/components/modals/ConfirmDeleteModal.vue'

const supabaseHook = useSupabase()
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
} = supabaseHook

// Usar composables
const { isModalOpen, openModal, closeModal } = useNewTaskModal('calendar')
const {
  dayFilterActive,
  filteredByDate,
  allTasksRef,
  filters,
  hasActiveFilters,
  activeFilterDescription,
  filterByDay,
  clearDayFilter,
  clearAllFilters,
  updateFilters,
  isDayFiltered
} = useCalendarFilters(supabaseHook)

// Estado local
const viewMode = ref('month')
const selectedDate = ref(null)
const calendar = ref(null)
const creatingTask = ref(false)
const selectedDateForTask = ref(null)
const editingTask = ref(null)

const deleteConfirmModal = ref({
  isOpen: false,
  taskId: null,
  taskTitle: '',
  loading: false
})

// Computadas
const displayedTasksCount = computed(() => tasks.value.length)
const allTasksCount = computed(() => allTasksRef.value.length)

const pendingTasksCount = computed(() =>
  tasks.value.filter(task => task.status === 'pending').length
)

const completedTasksCount = computed(() =>
  tasks.value.filter(task => task.status === 'completed').length
)

const thisMonthTasksCount = computed(() => {
  const currentMonth = new Date().getMonth()
  const currentYear = new Date().getFullYear()

  return tasks.value.filter(task => {
    if (!task.due_date) return false
    const taskDate = new Date(task.due_date)
    return taskDate.getMonth() === currentMonth && taskDate.getFullYear() === currentYear
  }).length
})

const calendarAttributes = computed(() => {
  const attributes = []
  const tasksToShow = dayFilterActive.value ? allTasksRef.value : tasks.value
  const tasksByDate = {}

  tasksToShow.forEach(task => {
    if (!task.due_date) return
    const dateKey = task.due_date.split('T')[0]
    if (!tasksByDate[dateKey]) {
      tasksByDate[dateKey] = []
    }
    tasksByDate[dateKey].push(task)
  })

  Object.entries(tasksByDate).forEach(([date, dayTasks]) => {
    const completedCount = dayTasks.filter(t => t.status === 'completed').length
    const pendingCount = dayTasks.filter(t => t.status === 'pending').length
    const hasHighPriority = dayTasks.some(t => t.priority === 'high')

    let highlightColor = '#f3f4f6'

    if (dayFilterActive.value && filteredByDate.value === date) {
      highlightColor = '#dbeafe'
    } else if (pendingCount > 0 && hasHighPriority) {
      highlightColor = '#fef2f2'
    } else if (pendingCount > 0) {
      highlightColor = '#eff6ff'
    } else if (completedCount > 0) {
      highlightColor = '#f0fdf4'
    }

    attributes.push({
      key: `tasks-${date}`,
      dates: new Date(date),
      highlight: {
        color: highlightColor,
        fillMode: 'light'
      },
      bar: dayFilterActive.value && filteredByDate.value === date ? {
        color: '#3b82f6',
        fillMode: 'outline'
      } : null,
      popover: {
        label: `${dayTasks.length} tarea${dayTasks.length === 1 ? '' : 's'}`,
        visibility: 'hover'
      }
    })
  })

  return attributes
})

// ✅ COMPUTADA MEJORADA PARA TAREAS DEL DÍA SELECCIONADO
const selectedDayTasks = computed(() => {
  if (!selectedDate.value) return []

  const dateStr = selectedDate.value.id.split('T')[0]

  // Si hay filtro por día activo y coincide con el día seleccionado, mostrar las tareas filtradas
  if (dayFilterActive.value && filteredByDate.value === dateStr) {
    return tasks.value.filter(task =>
      task.due_date && task.due_date.split('T')[0] === dateStr
    ).sort(sortTasksByPriority)
  }

  // Si no hay filtro por día, mostrar todas las tareas del día
  return getTasksForDay(selectedDate.value).sort(sortTasksByPriority)
})

// Función auxiliar para ordenar tareas
const sortTasksByPriority = (a, b) => {
  if (a.status !== b.status) {
    return a.status === 'pending' ? -1 : 1
  }
  const priorityOrder = { high: 3, medium: 2, normal: 1 }
  return (priorityOrder[b.priority] || 1) - (priorityOrder[a.priority] || 1)
}

// Métodos
const getTasksForDay = (day) => {
  const dateStr = day.id.split('T')[0]
  return allTasksRef.value.filter(task =>
    task.due_date && task.due_date.split('T')[0] === dateStr
  )
}

const getDisplayTasksForDay = (day) => {
  const dateStr = day.id.split('T')[0]

  // Si hay filtro por día activo y coincide con este día, mostrar tareas filtradas
  if (dayFilterActive.value && filteredByDate.value === dateStr) {
    return tasks.value.filter(task =>
      task.due_date && task.due_date.split('T')[0] === dateStr
    )
  }

  // Si no hay filtro, mostrar todas las tareas del día
  return getTasksForDay(day)
}

const isSelectedDay = (day) => {
  if (!selectedDate.value) return false
  return day.id === selectedDate.value.id
}

const isToday = (day) => {
  const today = new Date()
  return day.date.toDateString() === today.toDateString()
}

// ✅ MANEJO PRINCIPAL DEL EVENTO DE VCALENDAR
const handleVCalendarDayClick = async (day) => {
  console.log('📅 VCalendar - Día clickeado:', day.id)

  // Seleccionar el día
  selectedDate.value = day

  // Si el día tiene tareas, aplicar filtro
  const dayTasks = getTasksForDay(day)
  if (dayTasks.length > 0) {
    console.log('🔍 Aplicando filtro por día con', dayTasks.length, 'tareas')
    await handleFilterByDay(day)
  } else {
    console.log('📅 Día sin tareas, solo seleccionado')
    // Si no hay filtro activo y no hay tareas, limpiar cualquier filtro previo
    if (dayFilterActive.value) {
      await clearDayFilter()
    }
  }
}

// ✅ FUNCIÓN PARA APLICAR FILTRO POR DÍA
const handleFilterByDay = async (day) => {
  try {
    console.log('🔍 Aplicando filtro por día:', day.id)
    await filterByDay(day)
    console.log('✅ Filtro aplicado, tareas en selectedDayTasks:', selectedDayTasks.value.length)
  } catch (error) {
    console.error('❌ Error aplicando filtro por día:', error)
    push.error({
      title: 'Error al filtrar',
      message: 'No se pudo aplicar el filtro por día'
    })
  }
}

const handlePageChange = (page) => {
  console.log('📅 Página cambiada:', page)
}

const goToToday = () => {
  if (calendar.value) {
    calendar.value.move(new Date())
  }
  selectedDate.value = {
    id: new Date().toISOString(),
    date: new Date(),
    day: new Date().getDate()
  }
}

const createTaskForDate = () => {
  selectedDateForTask.value = selectedDate.value?.date
  editingTask.value = null
  openModal()
}

const handleEditTask = (task) => {
  editingTask.value = task
  selectedDateForTask.value = null
  openModal()
}

const handleCreateTask = async (taskData) => {
  creatingTask.value = true
  try {
    if (selectedDateForTask.value) {
      const dateString = selectedDateForTask.value.toISOString().split('T')[0]
      taskData.due_date = dateString
    }

    const newTask = await createTask(taskData)
    closeModal()
    selectedDateForTask.value = null

    push.success({
      title: 'Tarea creada',
      message: `"${taskData.title}" ha sido programada exitosamente`
    })

    // ✅ REFRESCAR FILTRO SI ESTÁ ACTIVO CON MEJOR MANEJO
    if (dayFilterActive.value && filteredByDate.value) {
      console.log('🔄 Refrescando filtro por día después de crear tarea')
      // Pequeño delay para que la BD se actualice
      setTimeout(async () => {
        try {
          await supabaseHook.filterTasksByDay(filteredByDate.value)
        } catch (refreshError) {
          console.error('❌ Error refrescando filtro:', refreshError)
          // Recargar todas las tareas como fallback
          await getTasks()
        }
      }, 200)
    }

  } catch (err) {
    console.error('❌ Error creando tarea:', err)
    push.error({
      title: 'Error al crear tarea',
      message: err.message || 'No se pudo crear la tarea. Inténtalo de nuevo.'
    })
  } finally {
    creatingTask.value = false
    editingTask.value = null
  }
}

const handleUpdateTask = async (taskData) => {
  creatingTask.value = true
  try {
    await updateTask(taskData.id, taskData)
    closeModal()

    push.success({
      title: 'Tarea actualizada',
      message: `"${taskData.title}" ha sido actualizada exitosamente`
    })

    // ✅ REFRESCAR FILTRO SI ESTÁ ACTIVO
    if (dayFilterActive.value && filteredByDate.value) {
      console.log('🔄 Refrescando filtro por día después de actualizar tarea')
      setTimeout(async () => {
        try {
          await supabaseHook.filterTasksByDay(filteredByDate.value)
        } catch (refreshError) {
          console.error('❌ Error refrescando filtro:', refreshError)
          await getTasks()
        }
      }, 200)
    }

  } catch (err) {
    console.error('❌ Error actualizando tarea:', err)
    push.error({
      title: 'Error al actualizar',
      message: err.message || 'No se pudo actualizar la tarea. Inténtalo de nuevo.'
    })
  } finally {
    creatingTask.value = false
    editingTask.value = null
  }
}

const handleDeleteTask = async (taskId) => {
  const task = tasks.value.find(t => t.id === taskId)
  if (!task) {
    push.error({
      title: 'Error',
      message: 'Tarea no encontrada'
    })
    return
  }

  deleteConfirmModal.value = {
    isOpen: true,
    taskId: taskId,
    taskTitle: task.title,
    loading: false
  }
}

const confirmDeleteTask = async () => {
  deleteConfirmModal.value.loading = true

  try {
    const taskTitle = deleteConfirmModal.value.taskTitle
    await deleteTask(deleteConfirmModal.value.taskId)

    push.success({
      title: 'Tarea eliminada',
      message: `"${taskTitle}" ha sido eliminada del calendario`
    })

    // ✅ REFRESCAR FILTRO SI ESTÁ ACTIVO
    if (dayFilterActive.value && filteredByDate.value) {
      console.log('🔄 Refrescando filtro por día después de eliminar tarea')
      setTimeout(async () => {
        try {
          await supabaseHook.filterTasksByDay(filteredByDate.value)
        } catch (refreshError) {
          console.error('❌ Error refrescando filtro:', refreshError)
          await getTasks()
        }
      }, 200)
    }

  } catch (err) {
    console.error('❌ Error eliminando tarea:', err)
    push.error({
      title: 'Error al eliminar',
      message: err.message || 'No se pudo eliminar la tarea. Inténtalo de nuevo.'
    })
  } finally {
    deleteConfirmModal.value = {
      isOpen: false,
      taskId: null,
      taskTitle: '',
      loading: false
    }
  }
}

const cancelDeleteTask = () => {
  deleteConfirmModal.value = {
    isOpen: false,
    taskId: null,
    taskTitle: '',
    loading: false
  }
}

// ✅ MANEJO MEJORADO DE ACTUALIZACIÓN DE ESTADO - IGUAL QUE TaskDetailView
const handleUpdateStatus = async (taskId, newStatus) => {
  try {
    console.log('🔄 Calendario - Actualizando estado:', { taskId, newStatus })

    // ✅ VERIFICAR QUE LA TAREA EXISTE LOCALMENTE PRIMERO
    const task = tasks.value.find(t => t.id === taskId)
    if (!task) {
      console.warn('⚠️ Tarea no encontrada localmente:', taskId)
      push.error({
        title: 'Error',
        message: 'Tarea no encontrada'
      })
      return
    }

    // ✅ VERIFICAR SI YA TIENE ESE ESTADO
    if (task.status === newStatus) {
      console.log('⚠️ Estado ya es el mismo, omitiendo actualización')
      return
    }

    console.log('📊 Cambiando estado:', { de: task.status, a: newStatus })

    // ✅ USAR updateTask EN LUGAR DE toggleTaskStatus (igual que TaskDetailView)
    await updateTask(taskId, { status: newStatus })

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

    // ✅ REFRESCAR FILTRO SI ESTÁ ACTIVO CON DEBOUNCE
    if (dayFilterActive.value && filteredByDate.value) {
      console.log('🔄 Refrescando filtro por día después de actualizar estado')
      // Pequeño delay para evitar condiciones de carrera
      setTimeout(async () => {
        try {
          await supabaseHook.filterTasksByDay(filteredByDate.value)
        } catch (refreshError) {
          console.error('❌ Error refrescando filtro:', refreshError)
          // No mostrar error al usuario, solo log
        }
      }, 100)
    }

    console.log('✅ Calendario - Estado actualizado exitosamente')

  } catch (err) {
    console.error('❌ Error actualizando estado:', err)

    // ✅ MANEJO ESPECÍFICO DE ERRORES
    let errorMessage = 'No se pudo actualizar el estado de la tarea'

    if (err.message && err.message.includes('no existe')) {
      errorMessage = 'La tarea ya no existe'
    } else if (err.message && err.message.includes('conexión')) {
      errorMessage = 'Error de conexión. Revisa tu internet.'
    }

    push.error({
      title: 'Error al actualizar',
      message: errorMessage
    })

    // ✅ REFRESCAR TAREAS EN CASO DE ERROR PARA SINCRONIZAR
    try {
      console.log('🔄 Refrescando tareas después de error')
      if (dayFilterActive.value && filteredByDate.value) {
        await supabaseHook.filterTasksByDay(filteredByDate.value)
      } else {
        await getTasks()
      }
    } catch (refreshError) {
      console.error('❌ Error refrescando después de error:', refreshError)
    }
  }
}

const handleCloseModal = () => {
  editingTask.value = null
  selectedDateForTask.value = null
  closeModal()
}

// ... resto del script ...

// ✅ MANEJO DE EVENTOS DESDE CALENDARDAY

// Evento de selección de día
const handleDaySelection = (day) => {
  console.log('📅 Seleccionando día:', day.id)
  selectedDate.value = day
}

// ✅ WATCHER MEJORADO PARA MANTENER REFERENCIA A TODAS LAS TAREAS
watch(tasks, (newTasks) => {
  if (!dayFilterActive.value) {
    allTasksRef.value = [...newTasks]
  }
}, { deep: true, immediate: true })

// Cargar tareas al montar
onMounted(async () => {
  console.log('🔧 Calendario - Componente montado')
  await getTasks()
  allTasksRef.value = [...tasks.value]
  goToToday()
})
</script>

<style scoped src="./CalendarioContainerComponent.css"></style>
