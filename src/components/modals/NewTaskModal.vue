<template>
  <TransitionRoot appear :show="isOpen" as="template">
    <Dialog as="div" @close="closeModal" class="relative z-10">
      <TransitionChild
        as="template"
        enter="duration-300 ease-out"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="duration-200 ease-in"
        leave-from="opacity-100"
        leave-to="opacity-0">
        <div class="fixed inset-0 bg-black/30 backdrop-blur-sm" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4 text-center">
          <TransitionChild
            as="template"
            enter="duration-300 ease-out"
            enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100"
            leave="duration-200 ease-in"
            leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95">
            <DialogPanel class="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all border border-gray-100">

              <!-- Header mejorado -->
              <div class="flex items-center justify-between mb-6">
                <DialogTitle as="h3" class="text-xl font-bold text-primary-800 flex items-center space-x-3">
                  <div class="p-2 bg-primary-100 rounded-full">
                    <PlusCircleIcon class="w-6 h-6 text-primary-600" />
                  </div>
                  <span>{{ presetDate ? 'Programar Tarea' : 'Nueva Tarea' }}</span>
                </DialogTitle>
                <button
                  @click="closeModal"
                  class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-full transition-all duration-200 group">
                  <XMarkIcon class="w-5 h-5 group-hover:scale-110 transition-transform" />
                </button>
              </div>

              <!-- Fecha preseleccionada mejorada -->
              <div v-if="presetDate" class="mb-6 p-4 bg-gradient-to-r from-primary-50 to-primary-100 rounded-xl border border-primary-200 relative overflow-hidden">
                <div class="flex items-center space-x-3 text-primary-700 relative z-10">
                  <div class="p-2 bg-primary-200 rounded-full">
                    <CalendarDaysIcon class="w-5 h-5 text-primary-700" />
                  </div>
                  <div>
                    <p class="text-sm font-medium text-primary-600">Programada para:</p>
                    <p class="font-bold text-primary-800">{{ formatPresetDate }}</p>
                  </div>
                </div>
                <!-- Patrón decorativo -->
                <div class="absolute top-0 right-0 w-20 h-20 bg-primary-200 rounded-full opacity-20 -translate-y-10 translate-x-10"></div>
              </div>

              <!-- Form con íconos mejorados -->
              <form @submit.prevent="handleSubmit" class="space-y-6">
                <!-- Título -->
                <div class="space-y-2">
                  <label for="title" class="flex items-center space-x-2 text-sm font-semibold text-gray-700">
                    <div class="p-1.5 bg-gray-100 rounded-lg">
                      <PencilSquareIcon class="w-4 h-4 text-gray-600" />
                    </div>
                    <span>Título de la tarea *</span>
                  </label>
                  <input
                    id="title"
                    v-model="form.title"
                    type="text"
                    required
                    placeholder="¿Qué necesitas hacer?"
                    class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-all duration-200 placeholder-gray-400"
                    :class="{ 'border-red-500 ring-2 ring-red-200': errors.title }" />
                  <p v-if="errors.title" class="mt-1 text-sm text-red-600 flex items-center space-x-1">
                    <ExclamationCircleIcon class="w-4 h-4" />
                    <span>{{ errors.title }}</span>
                  </p>
                </div>

                <!-- Descripción -->
                <div class="space-y-2">
                  <label for="description" class="flex items-center space-x-2 text-sm font-semibold text-gray-700">
                    <div class="p-1.5 bg-gray-100 rounded-lg">
                      <DocumentTextIcon class="w-4 h-4 text-gray-600" />
                    </div>
                    <span>Descripción (opcional)</span>
                  </label>
                  <textarea
                    id="description"
                    v-model="form.description"
                    rows="3"
                    placeholder="Agrega más detalles sobre esta tarea..."
                    class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-all duration-200 resize-none placeholder-gray-400"></textarea>
                </div>

                <!-- Fecha (solo si no hay fecha preseleccionada) -->
                <div v-if="!presetDate" class="space-y-2">
                  <label for="due_date" class="flex items-center space-x-2 text-sm font-semibold text-gray-700">
                    <div class="p-1.5 bg-blue-100 rounded-lg">
                      <CalendarDaysIcon class="w-4 h-4 text-blue-600" />
                    </div>
                    <span>Fecha de vencimiento (opcional)</span>
                  </label>
                  <div class="relative">
                    <input
                      id="due_date"
                      v-model="form.due_date"
                      type="date"
                      class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-all duration-200" />

                    <!-- Preview de fecha -->
                    <div v-if="form.due_date" class="mt-2">
                      <div class="inline-flex items-center space-x-2 text-xs font-medium text-blue-600 bg-blue-50 px-3 py-2 rounded-full border border-blue-200">
                        <CalendarDaysIcon class="w-3 h-3" />
                        <span>{{ formatDatePreview(form.due_date) }}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Hora mejorada -->
                <div class="space-y-2">
                  <label for="due_time" class="flex items-center space-x-2 text-sm font-semibold text-gray-700">
                    <div class="p-1.5 bg-orange-100 rounded-lg">
                      <ClockIcon class="w-4 h-4 text-orange-600" />
                    </div>
                    <span>Hora (opcional)</span>
                  </label>
                  <div class="relative">
                    <input
                      id="due_time"
                      v-model="form.due_time"
                      type="time"
                      step="300"
                      class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-all duration-200" />

                    <!-- Botón para limpiar hora mejorado -->
                    <button
                      v-if="form.due_time"
                      @click="form.due_time = ''"
                      type="button"
                      class="absolute right-3 top-1/2 transform -translate-y-1/2 p-1 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-full transition-all duration-200 group">
                      <XMarkIcon class="w-4 h-4 group-hover:scale-110 transition-transform" />
                    </button>
                  </div>

                  <!-- Preview de la hora mejorado -->
                  <div v-if="form.due_time" class="mt-2 space-y-2">
                    <div class="inline-flex items-center space-x-2 text-xs font-medium text-orange-600 bg-orange-50 px-3 py-2 rounded-full border border-orange-200">
                      <ClockIcon class="w-3 h-3" />
                      <span>{{ formatTimePreview(form.due_time) }}</span>
                    </div>
                    <!-- Tiempo relativo -->
                    <p class="text-xs text-gray-500 ml-2">{{ getTimeContext(form.due_time) }}</p>
                  </div>
                </div>

                <!-- Prioridad mejorada -->
                <div class="space-y-2">
                  <label for="priority" class="flex items-center space-x-2 text-sm font-semibold text-gray-700">
                    <div class="p-1.5 bg-purple-100 rounded-lg">
                      <ExclamationTriangleIcon class="w-4 h-4 text-purple-600" />
                    </div>
                    <span>Prioridad</span>
                  </label>
                  <div class="grid grid-cols-3 gap-2">
                    <!-- Botones de prioridad tipo radio -->
                    <button
                      type="button"
                      @click="form.priority = 'normal'"
                      :class="form.priority === 'normal' ?
                        'bg-gray-100 border-gray-300 text-gray-800 ring-2 ring-gray-200' :
                        'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'"
                      class="flex flex-col items-center space-y-2 p-3 border rounded-xl transition-all duration-200">
                      <div class="p-2 rounded-full" :class="form.priority === 'normal' ? 'bg-gray-200' : 'bg-gray-100'">
                        <MinusIcon class="w-4 h-4" />
                      </div>
                      <span class="text-xs font-medium">Normal</span>
                    </button>

                    <button
                      type="button"
                      @click="form.priority = 'medium'"
                      :class="form.priority === 'medium' ?
                        'bg-yellow-50 border-yellow-300 text-yellow-800 ring-2 ring-yellow-200' :
                        'bg-white border-gray-200 text-gray-600 hover:bg-yellow-50'"
                      class="flex flex-col items-center space-y-2 p-3 border rounded-xl transition-all duration-200">
                      <div class="p-2 rounded-full" :class="form.priority === 'medium' ? 'bg-yellow-200' : 'bg-gray-100'">
                        <ExclamationTriangleIcon class="w-4 h-4" :class="form.priority === 'medium' ? 'text-yellow-600' : 'text-gray-400'" />
                      </div>
                      <span class="text-xs font-medium">Media</span>
                    </button>

                    <button
                      type="button"
                      @click="form.priority = 'high'"
                      :class="form.priority === 'high' ?
                        'bg-red-50 border-red-300 text-red-800 ring-2 ring-red-200' :
                        'bg-white border-gray-200 text-gray-600 hover:bg-red-50'"
                      class="flex flex-col items-center space-y-2 p-3 border rounded-xl transition-all duration-200">
                      <div class="p-2 rounded-full" :class="form.priority === 'high' ? 'bg-red-200' : 'bg-gray-100'">
                        <FireIcon class="w-4 h-4" :class="form.priority === 'high' ? 'text-red-600' : 'text-gray-400'" />
                      </div>
                      <span class="text-xs font-medium">Alta</span>
                    </button>
                  </div>
                </div>

                <!-- Botones mejorados -->
                <div class="flex justify-end space-x-3 pt-6 border-t border-gray-100">
                  <button
                    type="button"
                    @click="closeModal"
                    class="px-6 py-3 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl transition-colors duration-200 flex items-center space-x-2">
                    <XMarkIcon class="w-4 h-4" />
                    <span>Cancelar</span>
                  </button>
                  <button
                    type="submit"
                    :disabled="loading"
                    class="px-6 py-3 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 rounded-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5">
                    <div v-if="loading" class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                    <CheckIcon v-else class="w-4 h-4" />
                    <span>{{ loading ? 'Creando...' : 'Crear Tarea' }}</span>
                  </button>
                </div>
              </form>
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup>
import { ref, reactive, watch, computed } from 'vue'
import {
  Dialog,
  DialogPanel,
  DialogTitle,
  TransitionChild,
  TransitionRoot,
} from '@headlessui/vue'
import {
  PlusCircleIcon,
  XMarkIcon,
  CalendarDaysIcon,
  ClockIcon,
  ExclamationTriangleIcon,
  PencilSquareIcon,
  DocumentTextIcon,
  ExclamationCircleIcon,
  CheckIcon,
  MinusIcon
} from '@heroicons/vue/24/outline'
import { FireIcon } from '@heroicons/vue/24/solid'

// Props
const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  },
  loading: {
    type: Boolean,
    default: false
  },
  presetDate: {
    type: Date,
    default: null
  }
})

// Emits
const emit = defineEmits(['close', 'submit'])

// Form data
const form = reactive({
  title: '',
  description: '',
  due_date: '',
  due_time: '',
  priority: 'normal'
})

// Validation errors
const errors = reactive({
  title: null
})

// Computed
const formatPresetDate = computed(() => {
  if (!props.presetDate) return ''
  return new Intl.DateTimeFormat('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }).format(props.presetDate)
})

// Helper para mostrar preview de la hora
const formatTimePreview = (timeStr) => {
  if (!timeStr) return ''
  try {
    const [hours, minutes] = timeStr.split(':')
    const hour12 = +hours === 0 ? 12 : +hours > 12 ? +hours - 12 : +hours
    const period = +hours >= 12 ? 'PM' : 'AM'
    return `${hour12}:${minutes} ${period}`
  } catch (error) {
    return timeStr
  }
}

// Helper para formato de fecha
const formatDatePreview = (dateStr) => {
  if (!dateStr) return ''
  try {
    return new Intl.DateTimeFormat('es-ES', {
      weekday: 'short',
      month: 'short',
      day: 'numeric'
    }).format(new Date(dateStr))
  } catch (error) {
    return dateStr
  }
}

// Contexto de tiempo
const getTimeContext = (timeStr) => {
  if (!timeStr) return ''
  try {
    const [hours] = timeStr.split(':')
    const hour = +hours

    if (hour >= 6 && hour < 12) return '🌅 Mañana'
    if (hour >= 12 && hour < 18) return '☀️ Tarde'
    if (hour >= 18 && hour < 22) return '🌆 Noche'
    return '🌙 Madrugada'
  } catch (error) {
    return ''
  }
}

// Methods
const closeModal = () => {
  resetForm()
  emit('close')
}

const resetForm = () => {
  form.title = ''
  form.description = ''
  form.due_date = ''
  form.due_time = ''
  form.priority = 'normal'
  errors.title = null
}

const validateForm = () => {
  errors.title = null

  if (!form.title.trim()) {
    errors.title = 'El título es requerido'
    return false
  }

  if (form.title.trim().length < 3) {
    errors.title = 'El título debe tener al menos 3 caracteres'
    return false
  }

  return true
}

const handleSubmit = () => {
  console.log('📝 Datos del formulario:', form)

  if (validateForm()) {
    const taskData = {
      title: form.title.trim(),
      description: form.description.trim() || null,
      priority: form.priority,
      status: 'pending'
    }

    // Manejar fecha
    if (props.presetDate) {
      const dateString = props.presetDate.toISOString().split('T')[0]
      taskData.due_date = dateString
    } else if (form.due_date) {
      taskData.due_date = form.due_date
    }

    // Manejar hora
    if (form.due_time && form.due_time.trim()) {
      taskData.due_time = form.due_time
    }

    console.log('🚀 Enviando tarea:', taskData)
    emit('submit', taskData)
  }
}

// Watchers
watch(() => props.isOpen, (newValue) => {
  if (!newValue) {
    setTimeout(() => {
      resetForm()
    }, 200)
  } else {
    errors.title = null
  }
})

watch(() => form.due_time, (newValue) => {
  console.log('⏰ Hora cambiada:', newValue)
})
</script>
