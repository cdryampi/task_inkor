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
        <div class="fixed inset-0 bg-black/25" />
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
            <DialogPanel class="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">

              <!-- Header -->
              <div class="flex items-center justify-between mb-6">
                <DialogTitle as="h3" class="text-lg font-semibold text-primary-800 flex items-center space-x-2">
                  <PlusCircleIcon class="w-6 h-6" />
                  <span>Nueva Tarea</span>
                </DialogTitle>
                <button
                  @click="closeModal"
                  class="text-gray-400 hover:text-gray-600 transition-colors">
                  <XMarkIcon class="w-5 h-5" />
                </button>
              </div>

              <!-- Form -->
              <form @submit.prevent="handleSubmit" class="space-y-4">
                <!-- Título -->
                <div>
                  <label for="title" class="block text-sm font-medium text-gray-700 mb-2">
                    Título de la tarea *
                  </label>
                  <input
                    id="title"
                    v-model="form.title"
                    type="text"
                    required
                    placeholder="¿Qué necesitas hacer?"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-colors"
                    :class="{ 'border-red-500': errors.title }" />
                  <p v-if="errors.title" class="mt-1 text-sm text-red-600">{{ errors.title }}</p>
                </div>

                <!-- Descripción -->
                <div>
                  <label for="description" class="block text-sm font-medium text-gray-700 mb-2">
                    Descripción (opcional)
                  </label>
                  <textarea
                    id="description"
                    v-model="form.description"
                    rows="3"
                    placeholder="Agrega más detalles sobre esta tarea..."
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-colors resize-none"></textarea>
                </div>

                <!-- Botones -->
                <div class="flex justify-end space-x-3 pt-4">
                  <button
                    type="button"
                    @click="closeModal"
                    class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors">
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    :disabled="loading"
                    class="px-4 py-2 text-sm font-medium text-white bg-primary-500 hover:bg-primary-600 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2">
                    <div v-if="loading" class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
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
import { reactive, watch } from 'vue'
import {
  Dialog,
  DialogPanel,
  DialogTitle,
  TransitionChild,
  TransitionRoot,
} from '@headlessui/vue'
import { PlusCircleIcon, XMarkIcon } from '@heroicons/vue/24/outline'

// Props
const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  },
  loading: {
    type: Boolean,
    default: false
  }
})

// Emits
const emit = defineEmits(['close', 'submit'])

// Form data
const form = reactive({
  title: '',
  description: ''
})

// Validation errors
const errors = reactive({
  title: null
})

// Methods
const closeModal = () => {
  // Reset form
  form.title = ''
  form.description = ''
  errors.title = null
  emit('close')
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
  if (validateForm()) {
    emit('submit', {
      title: form.title.trim(),
      description: form.description.trim() || null
    })
  }
}

// Reset form when modal closes
watch(() => props.isOpen, (newValue) => {
  if (!newValue) {
    setTimeout(() => {
      form.title = ''
      form.description = ''
      errors.title = null
    }, 200) // Wait for transition
  }
})
</script>
