<template>
  <div v-if="selectedDate" class="mt-6 bg-white rounded-lg shadow-sm border border-gray-200">
    <!-- Header -->
    <div class="p-4 border-b border-gray-200 bg-gradient-to-r from-primary-50 to-primary-100">
      <h3 class="text-lg font-semibold text-primary-800 flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <CalendarDaysIcon class="w-5 h-5" />
          <span>{{ formattedDate }}</span>
          <!-- Indicador de filtro activo -->
          <div v-if="isDayFiltered" class="px-2 py-1 bg-blue-200 text-blue-800 text-xs rounded-full flex items-center space-x-1">
            <FunnelIcon class="w-3 h-3" />
            <span>Filtrado</span>
          </div>
        </div>
        <div class="flex items-center space-x-2">
          <!-- Contador de tareas -->
          <div class="text-xs text-primary-700 bg-primary-200 px-2 py-1 rounded-full">
            {{ tasks.length }} tarea{{ tasks.length === 1 ? '' : 's' }}
          </div>

          <!-- Distribución de prioridades -->
          <div v-if="tasks.length > 0" class="flex items-center space-x-1 text-xs">
            <div v-if="highPriorityCount > 0"
                 class="flex items-center space-x-1 bg-red-100 text-red-700 px-2 py-1 rounded-full">
              <FireIconSolid class="w-3 h-3" />
              <span>{{ highPriorityCount }}</span>
            </div>
            <div v-if="mediumPriorityCount > 0"
                 class="flex items-center space-x-1 bg-yellow-100 text-yellow-700 px-2 py-1 rounded-full">
              <ExclamationTriangleIconSolid class="w-3 h-3" />
              <span>{{ mediumPriorityCount }}</span>
            </div>
          </div>
        </div>
      </h3>
    </div>

    <!-- Content -->
    <div class="p-4">
      <!-- Tareas -->
      <div v-if="tasks.length > 0" class="space-y-4">
        <TaskCard
          v-for="task in tasks"
          :key="task.id"
          :task="formatTaskForCard(task)"
          @edit-task="$emit('edit-task', $event)"
          @delete-task="$emit('delete-task', $event)"
          @update-status="handleUpdateStatus"
        />
      </div>

      <!-- Empty state -->
      <div v-else class="text-center py-12">
        <CalendarDaysIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
        <p class="text-gray-500 mb-4">No hay tareas programadas para este día</p>
        <button
          @click="$emit('create-task')"
          class="inline-flex items-center space-x-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors font-medium shadow-sm">
          <PlusCircleIcon class="w-4 h-4" />
          <span>Programar Tarea</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import {
  CalendarDaysIcon,
  PlusCircleIcon,
  FunnelIcon
} from '@heroicons/vue/24/outline'
import {
  ExclamationTriangleIcon as ExclamationTriangleIconSolid,
  FireIcon as FireIconSolid
} from '@heroicons/vue/24/solid'
import TaskCard from '@/components/tasks/TaskCard.vue'

const props = defineProps({
  selectedDate: {
    type: Object,
    default: null
  },
  tasks: {
    type: Array,
    default: () => []
  },
  isDayFiltered: {
    type: Boolean,
    default: false
  }
})

// ✅ DEFINIR EMITS CORRECTAMENTE
const emit = defineEmits(['edit-task', 'delete-task', 'update-status', 'create-task'])

// ✅ MANEJAR CORRECTAMENTE EL EVENTO UPDATE-STATUS
const handleUpdateStatus = (taskId, newStatus) => {
  console.log('📋 TaskSidebar - Recibiendo update-status:', { taskId, newStatus })
  console.log('📋 TaskSidebar - Tipos:', { taskIdType: typeof taskId, newStatusType: typeof newStatus })

  // ✅ VALIDAR PARÁMETROS
  if (!taskId || !newStatus) {
    console.error('❌ TaskSidebar - Parámetros inválidos:', { taskId, newStatus })
    return
  }

  console.log('📋 TaskSidebar - Emitiendo hacia CalendarioContainer:', { taskId, newStatus })

  // ✅ EMITIR CON AMBOS PARÁMETROS SEPARADOS
  emit('update-status', taskId, newStatus)
}

const formattedDate = computed(() => {
  if (!props.selectedDate) return ''
  return new Intl.DateTimeFormat('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }).format(props.selectedDate.date)
})

const highPriorityCount = computed(() =>
  props.tasks.filter(t => t.priority === 'high').length
)

const mediumPriorityCount = computed(() =>
  props.tasks.filter(t => t.priority === 'medium').length
)

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
</script>

<style scoped>
.task-sidebar {
  /* Estilos para el sidebar de tareas */
}

.tasks-list {
  /* Estilos para la lista de tareas */
}
</style>
