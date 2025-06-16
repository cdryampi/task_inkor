<template>
  <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center mb-6 space-y-4 sm:space-y-0">
    <h1 class="text-2xl font-bold text-primary-800 flex items-center space-x-2">
      <CalendarDaysIcon class="w-7 h-7" />
      <span>Calendario de Tareas</span>
    </h1>

    <div class="flex space-x-2">
      <button
        @click="$emit('go-to-today')"
        class="px-3 py-2 bg-accent text-white rounded-lg hover:bg-accent-light transition-colors font-medium">
        Hoy
      </button>
      <button
        @click="$emit('update:view-mode', 'month')"
        :class="viewMode === 'month' ? activeButtonClass : inactiveButtonClass">
        Mes
      </button>
      <button
        @click="$emit('update:view-mode', 'week')"
        :class="viewMode === 'week' ? activeButtonClass : inactiveButtonClass">
        Semana
      </button>
    </div>
  </div>
</template>

<script setup>
import { CalendarDaysIcon } from '@heroicons/vue/24/outline'

defineProps({
  viewMode: {
    type: String,
    default: 'month'
  }
})

defineEmits(['go-to-today', 'update:view-mode'])

const activeButtonClass = 'px-3 py-2 bg-primary-500 text-white rounded-lg font-medium shadow-sm'
const inactiveButtonClass = 'px-3 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors'
</script>
