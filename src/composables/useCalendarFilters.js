import { ref, computed } from 'vue'
import { push } from 'notivue'

export const useCalendarFilters = (supabaseHook) => {
  const dayFilterActive = ref(false)
  const filteredByDate = ref(null)
  const allTasksRef = ref([])

  const filters = ref({
    status: '',
    priority: '',
    dueDate: '',
    search: '',
    sortBy: 'due_time',
    sortOrder: 'asc'
  })

  const hasActiveFilters = computed(() => {
    return filters.value.status ||
           filters.value.priority ||
           filters.value.dueDate ||
           filters.value.search ||
           filters.value.sortBy !== 'due_time' ||
           filters.value.sortOrder !== 'asc' ||
           dayFilterActive.value
  })

  const activeFilterDescription = computed(() => {
    if (dayFilterActive.value && filteredByDate.value) {
      const date = new Date(filteredByDate.value)
      const formattedDate = new Intl.DateTimeFormat('es-ES', {
        weekday: 'long',
        day: 'numeric',
        month: 'long'
      }).format(date)
      return `Filtrado por día: ${formattedDate}`
    }
    return 'Filtros aplicados'
  })

  const filterByDay = async (day) => {
    try {
      console.log('📅 Filtrando tareas por día:', day)

      const dateStr = day.id.split('T')[0]
      filteredByDate.value = dateStr
      dayFilterActive.value = true

      await supabaseHook.filterTasksByDay(dateStr)

      push.success({
        title: 'Filtro por día aplicado',
        message: `Mostrando tareas del ${new Intl.DateTimeFormat('es-ES', {
          day: 'numeric',
          month: 'long'
        }).format(day.date)}`
      })

    } catch (err) {
      console.error('❌ Error filtrando por día:', err)
      push.error({
        title: 'Error al filtrar',
        message: 'No se pudo aplicar el filtro por día'
      })
    }
  }

  const clearDayFilter = async () => {
    try {
      console.log('🧹 Limpiando filtro por día')

      dayFilterActive.value = false
      filteredByDate.value = null

      await supabaseHook.restoreAllTasks()

      push.info({
        title: 'Filtro por día limpiado',
        message: 'Mostrando todas las tareas'
      })
    } catch (err) {
      console.error('❌ Error limpiando filtro por día:', err)
      push.error({
        title: 'Error',
        message: 'No se pudo limpiar el filtro por día'
      })
    }
  }

  const clearAllFilters = async () => {
    filters.value = {
      status: '',
      priority: '',
      dueDate: '',
      search: '',
      sortBy: 'due_time',
      sortOrder: 'asc'
    }

    await clearDayFilter()

    push.info({
      title: 'Filtros limpiados',
      message: 'Mostrando todas las tareas'
    })
  }

  const updateFilters = (newFilters) => {
    console.log('🔄 Actualizando filtros del calendario:', newFilters)
    filters.value = { ...newFilters }
  }

  const isDayFiltered = (day) => {
    if (!dayFilterActive.value || !filteredByDate.value) return false
    const dayStr = day.id.split('T')[0]
    return filteredByDate.value === dayStr
  }

  return {
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
  }
}
