<template>
  <TransitionRoot appear :show="isOpen" as="template">
    <Dialog as="div" @close="$emit('cancel')" class="relative z-50">
      <TransitionChild
        as="div"
        enter="duration-300 ease-out"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="duration-200 ease-in"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <!-- ✅ USAR CLASE PERSONALIZADA DEL CSS -->
        <div class="fixed inset-0 modal-overlay" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4 text-center">
          <TransitionChild
            as="div"
            enter="duration-300 ease-out"
            enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100"
            leave="duration-200 ease-in"
            leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95"
          >
            <DialogPanel class="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all fade-in-up">

              <!-- Icon con gradiente personalizado -->
              <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-br from-red-100 to-red-50 mb-4 border-2 border-red-200">
                <div class="relative">
                  <ExclamationTriangleIcon class="h-8 w-8 text-red-600" />
                  <!-- Efecto de pulso sutil -->
                  <div class="absolute inset-0 rounded-full animate-ping">
                    <ExclamationTriangleIcon class="h-8 w-8 text-red-400 opacity-20" />
                  </div>
                </div>
              </div>

              <!-- Title con colores personalizados -->
              <DialogTitle as="h3" class="text-xl font-semibold leading-6 text-gray-800 text-center mb-3">
                <span class="flex items-center justify-center space-x-2">
                  <TrashIcon class="h-5 w-5 text-red-600" />
                  <span>Eliminar Tarea</span>
                </span>
              </DialogTitle>

              <!-- Content con mejor diseño -->
              <div class="text-center mb-6">
                <p class="text-gray-600 mb-4 leading-relaxed">
                  ¿Estás seguro de que quieres eliminar esta tarea?
                </p>

                <!-- Task preview card -->
                <div class="bg-gradient-to-r from-gray-50 to-gray-100 border border-gray-200 rounded-lg p-3 mb-4">
                  <div class="flex items-center space-x-2">
                    <ClipboardDocumentListIcon class="h-4 w-4 text-gray-500 flex-shrink-0" />
                    <p class="text-sm font-medium text-gray-900 truncate">
                      {{ taskTitle }}
                    </p>
                  </div>
                </div>

                <!-- Warning message -->
                <div class="flex items-center justify-center space-x-2 bg-red-50 border border-red-200 rounded-lg p-2">
                  <ExclamationCircleIcon class="h-4 w-4 text-red-600 flex-shrink-0" />
                  <p class="text-xs text-red-700 font-medium">
                    Esta acción no se puede deshacer
                  </p>
                </div>
              </div>

              <!-- Actions con estilos personalizados -->
              <div class="flex space-x-3">
                <!-- Botón Cancelar -->
                <button
                  type="button"
                  :disabled="loading"
                  @click="$emit('cancel')"
                  class="flex-1 inline-flex justify-center items-center space-x-2 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                >
                  <XMarkIcon class="h-4 w-4" />
                  <span>Cancelar</span>
                </button>

                <!-- Botón Eliminar -->
                <button
                  type="button"
                  :disabled="loading"
                  @click="$emit('confirm')"
                  class="flex-1 inline-flex justify-center items-center space-x-2 rounded-lg border border-transparent bg-gradient-to-r from-red-600 to-red-700 px-4 py-2.5 text-sm font-medium text-white hover:from-red-700 hover:to-red-800 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-105 active:scale-95"
                >
                  <!-- Loading spinner -->
                  <div v-if="loading" class="flex items-center space-x-2">
                    <div class="inline-block animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
                    <span>Eliminando...</span>
                  </div>

                  <!-- Normal state -->
                  <div v-else class="flex items-center space-x-2">
                    <TrashIcon class="h-4 w-4" />
                    <span>Eliminar</span>
                  </div>
                </button>
              </div>

              <!-- Footer subtle -->
              <div class="mt-4 pt-3 border-t border-gray-100">
                <p class="text-xs text-gray-500 text-center">
                  Presiona <kbd class="px-1.5 py-0.5 text-xs font-mono bg-gray-100 border border-gray-300 rounded">Esc</kbd> para cancelar
                </p>
              </div>
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup>
import {
  Dialog,
  DialogPanel,
  DialogTitle,
  TransitionChild,
  TransitionRoot,
} from '@headlessui/vue'
import {
  ExclamationTriangleIcon,
  TrashIcon,
  XMarkIcon,
  ClipboardDocumentListIcon,
  ExclamationCircleIcon
} from '@heroicons/vue/24/outline'

defineProps({
  isOpen: {
    type: Boolean,
    default: false
  },
  taskTitle: {
    type: String,
    default: ''
  },
  loading: {
    type: Boolean,
    default: false
  }
})

defineEmits(['confirm', 'cancel'])
</script>

<style scoped>
/* Animación personalizada para el kbd */
kbd {
  box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
}

/* Efecto hover mejorado para botones */
button:hover:not(:disabled) {
  transform: translateY(-1px);
}

button:active:not(:disabled) {
  transform: translateY(0);
}

/* Mejora del spinner */
.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
