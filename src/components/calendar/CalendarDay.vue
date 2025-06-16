<template>
  <div
    class="relative w-full h-full min-h-[80px] p-1 transition-all duration-200 rounded group"
    :class="dayClasses"
    :data-day-id="day.id"
    :data-has-tasks="allTasks.length > 0"
    @click="handleDayClick">

    <!-- Número del día -->
    <div class="flex justify-between items-start">
      <span class="text-sm font-medium text-gray-800">{{ day.day }}</span>
      <div class="flex items-center space-x-1">
        <div v-if="isToday" class="w-2 h-2 bg-accent rounded-full animate-pulse"></div>
        <div v-if="isSelected" class="w-2 h-2 bg-primary-500 rounded-full"></div>
        <div v-if="isFiltered" class="w-2 h-2 bg-blue-500 rounded-full"></div>
      </div>
    </div>

    <!-- Tareas del día -->
    <div v-if="displayTasks.length > 0" class="mt-1 space-y-1">
      <div
        v-for="(task, index) in displayTasks.slice(0, 3)"
        :key="task.id"
        :class="getTaskBarClass(task)"
        class="text-xs px-2 py-1 rounded text-white truncate font-medium shadow-sm flex items-center space-x-1 relative overflow-hidden">

        <!-- Ícono de prioridad -->
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
        v-if="displayTasks.length > 3"
        class="text-xs text-gray-500 pl-2 font-medium flex items-center space-x-1">
        <ChevronUpIcon class="w-3 h-3" />
        <span>+{{ displayTasks.length - 3 }} más</span>
      </div>
    </div>

    <!-- Indicador de click para filtrar -->
    <div v-if="allTasks.length > 0 && !isFiltered"
         class="absolute top-1 right-1 opacity-0 group-hover:opacity-100 transition-opacity">
      <div class="bg-white rounded-full p-1 shadow-sm border border-primary-200">
        <FunnelIcon class="w-3 h-3 text-primary-600" />
      </div>
    </div>

    <!-- Indicador de filtro aplicado -->
    <div v-if="isFiltered"
         class="absolute top-1 right-1">
      <div class="bg-blue-500 rounded-full p-1 shadow-sm">
        <FunnelIcon class="w-3 h-3 text-white" />
      </div>
    </div>

    <!-- Overlay para indicar que es clickeable -->
    <div v-if="allTasks.length > 0"
         class="absolute inset-0 bg-gradient-to-br from-transparent to-primary-50 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none rounded">
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { ChevronUpIcon, FunnelIcon, MinusIcon } from '@heroicons/vue/24/outline'
import { ExclamationTriangleIcon as ExclamationTriangleIconSolid, FireIcon as FireIconSolid } from '@heroicons/vue/24/solid'

const props = defineProps({
  day: {
    type: Object,
    required: true
  },
  allTasks: {
    type: Array,
    default: () => []
  },
  displayTasks: {
    type: Array,
    default: () => []
  },
  isToday: {
    type: Boolean,
    default: false
  },
  isSelected: {
    type: Boolean,
    default: false
  },
  isFiltered: {
    type: Boolean,
    default: false
  }
})

// ✅ DEFINIR EMITS
const emit = defineEmits(['day-click', 'filter-by-day'])

const dayClasses = computed(() => {
  return {
    'cursor-pointer': props.allTasks.length > 0,
    'hover:bg-primary-50': !props.isFiltered && !props.isSelected && props.allTasks.length > 0,
    'bg-blue-100 ring-2 ring-blue-500 hover:bg-blue-200': props.isFiltered,
    'bg-primary-100 ring-2 ring-primary-500': props.isSelected && !props.isFiltered,
    'hover:ring-2 hover:ring-primary-300 hover:shadow-md hover:scale-105': props.allTasks.length > 0
  }
})

// ✅ FUNCIÓN PARA MANEJAR EL CLICK
const handleDayClick = (event) => {
  console.log('📅 CalendarDay - Click detectado en día:', props.day.id)

  // Prevenir propagación para evitar conflictos con VCalendar
  event.stopPropagation()

  // Emitir eventos al componente padre
  emit('day-click', props.day)

  // Si el día tiene tareas, también emitir evento de filtro
  if (props.allTasks.length > 0) {
    console.log('🔍 CalendarDay - Emitiendo filter-by-day para', props.allTasks.length, 'tareas')
    emit('filter-by-day', props.day)
  }
}

const getPriorityIcon = (priority) => {
  switch (priority) {
    case 'high': return FireIconSolid
    case 'medium': return ExclamationTriangleIconSolid
    default: return MinusIcon
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
</script>

<style scoped>
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.animate-shimmer {
  animation: shimmer 2s infinite;
}
</style>
