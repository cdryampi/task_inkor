<template>
  <div v-if="hasActiveFilters" class="mb-4 p-3 bg-gradient-to-r from-primary-50 to-primary-100 border border-primary-200 rounded-lg">
    <div class="flex items-center justify-between">
      <div class="flex items-center space-x-2">
        <FunnelIcon class="w-4 h-4 text-primary-600" />
        <span class="text-sm font-medium text-primary-800">
          {{ activeFilterDescription }} - Mostrando {{ displayedTasksCount }} de {{ allTasksCount }} tareas
        </span>
      </div>
      <div class="flex items-center space-x-2">
        <!-- Botón específico para limpiar filtro por día -->
        <button
          v-if="dayFilterActive"
          @click="$emit('clear-day-filter')"
          class="text-xs text-blue-600 hover:text-blue-800 underline flex items-center space-x-1">
          <CalendarDaysIcon class="w-3 h-3" />
          <span>Limpiar filtro por día</span>
        </button>

        <button
          @click="$emit('clear-all-filters')"
          class="text-xs text-primary-600 hover:text-primary-800 underline flex items-center space-x-1">
          <XMarkIcon class="w-3 h-3" />
          <span>Limpiar todos</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { FunnelIcon, XMarkIcon, CalendarDaysIcon } from '@heroicons/vue/24/outline'

defineProps({
  hasActiveFilters: {
    type: Boolean,
    default: false
  },
  activeFilterDescription: {
    type: String,
    default: ''
  },
  displayedTasksCount: {
    type: Number,
    default: 0
  },
  allTasksCount: {
    type: Number,
    default: 0
  },
  dayFilterActive: {
    type: Boolean,
    default: false
  }
})

defineEmits(['clear-day-filter', 'clear-all-filters'])
</script>
