<template>
  <div class="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4">
    <div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
      <div class="flex items-center space-x-3">
        <div class="p-2 bg-primary-100 rounded-lg">
          <ClipboardDocumentListIcon class="w-5 h-5 text-primary-600" />
        </div>
        <div>
          <p class="text-sm text-gray-600">
            {{ dayFilterActive ? 'Tareas del día' : 'Total Tareas' }}
          </p>
          <p class="text-lg font-semibold text-gray-800">{{ displayedTasksCount }}</p>
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
          <p class="text-lg font-semibold text-gray-800">{{ pendingTasksCount }}</p>
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
          <p class="text-lg font-semibold text-gray-800">{{ completedTasksCount }}</p>
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
          <p class="text-lg font-semibold text-gray-800">{{ thisMonthTasksCount }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import {
  CalendarDaysIcon,
  CheckCircleIcon,
  ClipboardDocumentListIcon,
  ClockIcon
} from '@heroicons/vue/24/outline'

defineProps({
  displayedTasksCount: {
    type: Number,
    default: 0
  },
  pendingTasksCount: {
    type: Number,
    default: 0
  },
  completedTasksCount: {
    type: Number,
    default: 0
  },
  thisMonthTasksCount: {
    type: Number,
    default: 0
  },
  dayFilterActive: {
    type: Boolean,
    default: false
  }
})
</script>
