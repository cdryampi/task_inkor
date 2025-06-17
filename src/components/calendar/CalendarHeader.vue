<template>
  <div class="flex flex-col sm:flex-row mb-6 space-y-4 sm:space-y-0">
    <h1 class="text-2xl font-bold text-primary-800 flex items-center space-x-2 text-center">
      <CalendarDaysIcon class="w-7 h-7" />
      <span>Calendario de Tareas</span>
    </h1>
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

</script>
