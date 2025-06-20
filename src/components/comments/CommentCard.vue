<template>
  <div
    class="border border-gray-200 rounded-xl p-4 transition-all duration-200 relative"
    :class="[
      commentTypeClass,
      { 'opacity-50 pointer-events-none': deleting }
    ]"
  >
    <!-- Comment Header -->
    <div class="flex items-start gap-3 mb-3">
      <!-- Avatar -->
      <div class="w-12 h-12 rounded-full flex items-center justify-center flex-shrink-0" :class="avatarBgClass">
        <ChibiAvatar
          v-if="comment.role === 'assistant'"
          :emotional-state="comment.emotional_state || 'supportive'"
          size="medium"
          :show-emotional-indicator="true"
        />
        <UserIconSolid
          v-else
          class="w-6 h-6 text-blue-600"
        />
      </div>

      <!-- Meta Information -->
      <div class="flex-1">
        <div class="flex items-center gap-2 mb-0.5">
          <span class="font-medium" :class="authorClass">
            {{ comment.role === 'assistant' ? 'MotivBot' : 'Tú' }}
          </span>
          <span v-if="comment.role === 'assistant'" class="ai-badge">
            <SparklesIcon class="w-3 h-3" />
            AI
            <span v-if="comment.emotional_state" class="ml-1 text-xs">
              {{ getEmotionalStateLabel(comment.emotional_state) }}
            </span>
          </span>
        </div>
        <div class="text-gray-500 text-sm">
          {{ formatRelativeTime(comment.created_at) }}
        </div>
      </div>

      <!-- Actions -->
      <div class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
        <button
          v-if="comment.role === 'user'"
          @click="askAI"
          :disabled="aiLoading"
          class="action-btn"
          :class="{ 'opacity-60 cursor-not-allowed': aiLoading }"
          :title="aiLoading ? 'Pidiendo consejo...' : 'Pedir consejo a la AI'"
        >
          <div v-if="aiLoading" class="loading-spinner"></div>
          <SparklesIcon v-else class="w-4 h-4" />
        </button>

        <button
          @click="copyContent"
          class="action-btn hover:bg-sky-50 hover:text-sky-600"
          :title="copied ? 'Copiado!' : 'Copiar contenido'"
        >
          <component :is="copied ? CheckIcon : ClipboardIcon" class="w-4 h-4" />
        </button>

        <button
          @click="deleteComment"
          class="action-btn hover:bg-red-50 hover:text-red-600"
          :title="`Eliminar ${comment.role === 'assistant' ? 'respuesta AI' : 'comentario'}`"
        >
          <TrashIcon class="w-4 h-4" />
        </button>
      </div>
    </div>

    <!-- Comment Content -->
    <div class="ml-15"> <!-- Ajustado para el nuevo tamaño de avatar -->
      <p class="text-gray-700 leading-relaxed mb-3">{{ comment.message }}</p>

      <!-- AI Suggestions -->
      <div
        v-if="comment.role === 'assistant' && comment.suggestions && comment.suggestions.length > 0"
        class="bg-purple-50 border border-purple-200 rounded-lg p-3 mt-3"
      >
        <h4 class="flex items-center gap-1.5 text-purple-700 font-semibold text-sm mb-2">
          <LightBulbIcon class="w-4 h-4" />
          Sugerencias:
        </h4>
        <ul class="space-y-1">
          <li
            v-for="(suggestion, index) in comment.suggestions"
            :key="index"
            class="text-gray-600 text-sm leading-relaxed pl-3 relative"
          >
            <span class="absolute left-0 text-purple-600 font-bold">•</span>
            {{ suggestion }}
          </li>
        </ul>
      </div>
    </div>

    <!-- Reactions -->
    <div class="flex gap-2 ml-15 mt-3 pt-3 border-t border-gray-100">
      <button
        @click="toggleReaction('useful')"
        class="reaction-btn"
        :class="{
          'bg-blue-100 border-blue-300 text-blue-700': comment.role === 'user' ? comment.user_is_useful : comment.assistant_is_useful
        }"
      >
        <HandThumbUpIcon class="w-4 h-4" />
        <span>Útil</span>
      </button>

      <button
        v-if="comment.role === 'assistant'"
        @click="toggleReaction('precise')"
        class="reaction-btn"
        :class="{ 'bg-green-100 border-green-300 text-green-700': comment.assistant_is_precise }"
      >
        <CheckBadgeIcon class="w-4 h-4" />
        <span>Preciso</span>
      </button>

      <button
        @click="toggleReaction('grateful')"
        class="reaction-btn"
        :class="{
          'bg-pink-100 border-pink-300 text-pink-700': comment.role === 'user' ? comment.user_is_grateful : comment.assistant_is_grateful
        }"
      >
        <HeartIcon class="w-4 h-4" />
        <span>Gracias</span>
      </button>

      <!-- Token Usage (solo para mensajes del asistente) -->
      <div v-if="comment.role === 'assistant' && comment.tokens_used" class="ml-auto flex items-center text-xs text-gray-400">
        <span>{{ comment.tokens_used }} tokens</span>
        <span v-if="comment.response_time_ms" class="ml-2">
          {{ Math.round(comment.response_time_ms / 1000) }}s
        </span>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div
      v-if="showDeleteConfirm"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      @click="showDeleteConfirm = false"
    >
      <div class="bg-white rounded-xl p-6 max-w-sm w-11/12 shadow-2xl" @click.stop>
        <div class="flex items-center gap-3 mb-4">
          <ExclamationTriangleIcon class="w-6 h-6 text-red-500 flex-shrink-0" />
          <h3 class="text-lg font-semibold text-gray-900">
            Confirmar eliminación
          </h3>
        </div>
        <p class="text-gray-600 mb-6">
          ¿Estás seguro de que quieres eliminar {{ comment.role === 'assistant' ? 'esta respuesta de la AI' : 'este comentario' }}?
          Esta acción no se puede deshacer.
        </p>
        <div class="flex gap-3 justify-end">
          <button
            @click="showDeleteConfirm = false"
            class="px-4 py-2 text-gray-500 hover:text-gray-700 transition-colors"
          >
            Cancelar
          </button>
          <button
            @click="confirmDelete"
            :disabled="deleting"
            class="px-4 py-2 bg-red-500 text-white rounded-md hover:bg-red-600 disabled:opacity-50 transition-colors"
          >
            <span v-if="deleting">Eliminando...</span>
            <span v-else>Eliminar</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import {
  UserIcon,
  SparklesIcon,
  TrashIcon,
  ClipboardIcon,
  CheckIcon,
  LightBulbIcon,
  HandThumbUpIcon,
  HeartIcon,
  CheckBadgeIcon,
  ExclamationTriangleIcon
} from '@heroicons/vue/24/outline'
import {
  SparklesIcon as SparklesIconSolid,
  UserIcon as UserIconSolid
} from '@heroicons/vue/24/solid'
import ChibiAvatar from '../ui/ChibiAvatar.vue'

// Props
const props = defineProps({
  comment: {
    type: Object,
    required: true,
    validator: (comment) => {
      // Validar que el comentario tenga la estructura correcta
      return comment &&
             typeof comment === 'object' &&
             ['user', 'assistant'].includes(comment.role) &&
             typeof comment.message === 'string'
    }
  },
  aiLoading: {
    type: Boolean,
    default: false
  }
})

// Emits
const emit = defineEmits(['delete', 'ask-ai', 'update-feedback'])

// State
const copied = ref(false)
const showDeleteConfirm = ref(false)
const deleting = ref(false)

// Computed
const commentTypeClass = computed(() => {
  return props.comment.role === 'assistant'
    ? 'bg-gradient-to-br from-purple-50 to-white border-l-4 border-l-purple-500 group hover:shadow-lg hover:-translate-y-0.5'
    : 'bg-gradient-to-br from-blue-50 to-white border-l-4 border-l-blue-500 group hover:shadow-lg hover:-translate-y-0.5'
})

const avatarBgClass = computed(() => {
  return props.comment.role === 'assistant'
    ? 'bg-gradient-to-br from-purple-100 to-purple-200'
    : 'bg-gradient-to-br from-blue-100 to-blue-200'
})

const authorClass = computed(() => {
  return props.comment.role === 'assistant'
    ? 'text-purple-800'
    : 'text-blue-800'
})

// Methods
const formatRelativeTime = (dateString) => {
  const now = new Date()
  const commentDate = new Date(dateString)
  const diffInMinutes = Math.floor((now - commentDate) / (1000 * 60))

  if (diffInMinutes < 1) return 'ahora'
  if (diffInMinutes < 60) return `hace ${diffInMinutes}m`

  const diffInHours = Math.floor(diffInMinutes / 60)
  if (diffInHours < 24) return `hace ${diffInHours}h`

  const diffInDays = Math.floor(diffInHours / 24)
  if (diffInDays < 7) return `hace ${diffInDays}d`

  return commentDate.toLocaleDateString('es-ES')
}

const copyContent = async () => {
  try {
    await navigator.clipboard.writeText(props.comment.message)
    copied.value = true
    setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch (err) {
    console.error('Error copiando contenido:', err)
  }
}

const deleteComment = () => {
  showDeleteConfirm.value = true
}

const confirmDelete = async () => {
  deleting.value = true
  try {
    emit('delete', props.comment.id)
    showDeleteConfirm.value = false
  } catch (err) {
    console.error('Error eliminando comentario:', err)
  } finally {
    deleting.value = false
  }
}

const askAI = () => {
  console.log('💬 CommentCard - Solicitando consejo de AI para:', props.comment.message)
  emit('ask-ai', props.comment.message)
}

// ✅ Actualizado para trabajar con el nuevo sistema de feedback
const toggleReaction = (type) => {
  const feedbackData = {}

  switch (type) {
    case 'useful':
      if (props.comment.role === 'user') {
        feedbackData.isUseful = !props.comment.user_is_useful
      } else {
        feedbackData.assistantIsUseful = !props.comment.assistant_is_useful
      }
      break
    case 'precise':
      feedbackData.isPrecise = !props.comment.assistant_is_precise
      break
    case 'grateful':
      if (props.comment.role === 'user') {
        feedbackData.isGrateful = !props.comment.user_is_grateful
      } else {
        feedbackData.assistantIsGrateful = !props.comment.assistant_is_grateful
      }
      break
  }

  console.log('👍 CommentCard - Actualizando feedback:', {
    commentId: props.comment.id,
    type,
    feedbackData
  })

  emit('update-feedback', props.comment.id, feedbackData)
}

const getEmotionalStateLabel = (state) => {
  const labels = {
    happy: '😊',
    excited: '🎉',
    calm: '😌',
    focused: '🎯',
    supportive: '🤗',
    encouraging: '💪',
    thoughtful: '🤔',
    energetic: '⚡'
  }
  return labels[state] || '🤖'
}
</script>

<style scoped>
/* AI Badge con gradiente personalizado */
.ai-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: white;
  font-size: 0.75rem;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 9999px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  background: linear-gradient(135deg, #8b5cf6, #7c3aed);
}

/* Action buttons */
.action-btn {
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
  color: #6b7280;
  background-color: transparent;
}

.action-btn:hover {
  transform: scale(1.05);
  background-color: #f3e8ff;
  color: #8b5cf6;
}

/* Reaction buttons */
.reaction-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  border: 1px solid #e5e7eb;
  border-radius: 9999px;
  background-color: white;
  color: #4b5563;
  font-size: 0.75rem;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.reaction-btn:hover {
  border-color: #d1d5db;
  background-color: #f9fafb;
}

/* Loading spinner */
.loading-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid #e5e7eb;
  border-top: 2px solid #8b5cf6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Ajuste para el nuevo margen */
.ml-15 {
  margin-left: 3.75rem; /* 60px */
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .ml-15 {
    margin-left: 0 !important;
  }

  .flex.gap-1.opacity-0 {
    opacity: 1 !important;
  }

  /* Avatar más pequeño en móvil */
  .w-12.h-12 {
    width: 2.5rem !important;
    height: 2.5rem !important;
  }
}
</style>
