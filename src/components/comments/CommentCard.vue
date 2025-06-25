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
            <!-- ✅ CAMBIO: Usar icono en lugar de emoji -->
            <component
              v-if="comment.emotional_state"
              :is="getEmotionalStateIcon(comment.emotional_state)"
              class="w-3 h-3 ml-1"
              :class="getEmotionalStateColor(comment.emotional_state)"
              :title="comment.emotional_state"
            />
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

    <!-- Reactions con mejor estado visual -->
    <div class="flex gap-2 ml-15 mt-3 pt-3 border-t border-gray-100">
      <button
        @click="toggleReaction('useful')"
        class="reaction-btn"
        :class="{
          'reaction-btn-active bg-blue-100 border-blue-300 text-blue-700 shadow-sm': comment.role === 'user' ? comment.user_is_useful : comment.assistant_is_useful,
          'reaction-btn-inactive hover:bg-blue-50 hover:border-blue-200': !(comment.role === 'user' ? comment.user_is_useful : comment.assistant_is_useful)
        }"
      >
        <HandThumbUpIcon class="w-4 h-4" />
        <span>Útil</span>
        <!-- ✅ CAMBIO: Usar icono CheckIcon en lugar de checkmark de texto -->
        <CheckIcon v-if="comment.role === 'user' ? comment.user_is_useful : comment.assistant_is_useful" class="w-3 h-3 reaction-checkmark" />
      </button>

      <button
        v-if="comment.role === 'assistant'"
        @click="toggleReaction('precise')"
        class="reaction-btn"
        :class="{
          'reaction-btn-active bg-green-100 border-green-300 text-green-700 shadow-sm': comment.assistant_is_precise,
          'reaction-btn-inactive hover:bg-green-50 hover:border-green-200': !comment.assistant_is_precise
        }"
      >
        <CheckBadgeIcon class="w-4 h-4" />
        <span>Preciso</span>
        <CheckIcon v-if="comment.assistant_is_precise" class="w-3 h-3 reaction-checkmark" />
      </button>

      <button
        @click="toggleReaction('grateful')"
        class="reaction-btn"
        :class="{
          'reaction-btn-active bg-pink-100 border-pink-300 text-pink-700 shadow-sm': comment.role === 'user' ? comment.user_is_grateful : comment.assistant_is_grateful,
          'reaction-btn-inactive hover:bg-pink-50 hover:border-pink-200': !(comment.role === 'user' ? comment.user_is_grateful : comment.assistant_is_grateful)
        }"
      >
        <HeartIcon class="w-4 h-4" />
        <span>Gracias</span>
        <CheckIcon v-if="comment.role === 'user' ? comment.user_is_grateful : comment.assistant_is_grateful" class="w-3 h-3 reaction-checkmark" />
      </button>

      <!-- Token Usage (solo para mensajes del asistente) -->
      <div v-if="comment.role === 'assistant' && (comment.tokens_used || comment.model_used)" class="ml-auto flex items-center text-xs text-gray-400 gap-3">
        <!-- Modelo utilizado -->
        <div v-if="comment.model_used" class="flex items-center gap-1">
          <CpuChipIcon class="w-3 h-3" />
          <span class="font-mono">{{ formatModelName(comment.model_used) }}</span>
        </div>

        <!-- Tokens y tiempo de respuesta -->
        <div v-if="comment.tokens_used" class="flex items-center gap-2">
          <span>{{ comment.tokens_used }} tokens</span>
          <span v-if="comment.response_time_ms" class="flex items-center gap-1">
            <ClockIcon class="w-3 h-3" />
            {{ Math.round(comment.response_time_ms / 1000) }}s
          </span>
        </div>
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
  ExclamationTriangleIcon,
  CpuChipIcon,
  ClockIcon,
  // ✅ Nuevos iconos para estados emocionales
  FaceSmileIcon,
  BoltIcon,
  CloudIcon,
  EyeIcon,
  HandRaisedIcon,
  BeakerIcon
} from '@heroicons/vue/24/outline'
import {
  SparklesIcon as SparklesIconSolid,
  UserIcon as UserIconSolid,
  // ✅ Iconos sólidos para estados emocionales
  FaceSmileIcon as FaceSmileIconSolid,
  BoltIcon as BoltIconSolid,
  CloudIcon as CloudIconSolid,
  EyeIcon as EyeIconSolid,
  HandRaisedIcon as HandRaisedIconSolid,
  BeakerIcon as BeakerIconSolid,
  HeartIcon as HeartIconSolid
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

// ✅ Corrección del bug en la función toggleReaction
const toggleReaction = (type) => {
  const feedbackData = {}

  switch (type) {
    case 'useful':
      if (props.comment.role === 'user') {
        feedbackData.user_is_useful = !props.comment.user_is_useful
      } else {
        feedbackData.assistant_is_useful = !props.comment.assistant_is_useful
      }
      break
    case 'precise':
      feedbackData.assistant_is_precise = !props.comment.assistant_is_precise
      break
    case 'grateful':
      if (props.comment.role === 'user') {
        feedbackData.user_is_grateful = !props.comment.user_is_grateful // ✅ CORREGIDO
      } else {
        feedbackData.assistant_is_grateful = !props.comment.assistant_is_grateful // ✅ CORREGIDO
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

// ✅ NUEVA función con iconos en lugar de emojis
const getEmotionalStateIcon = (state) => {
  const icons = {
    happy: FaceSmileIconSolid,
    excited: SparklesIconSolid,
    calm: CloudIconSolid,
    focused: EyeIconSolid,
    supportive: HandRaisedIconSolid,
    encouraging: HeartIconSolid,
    thoughtful: BeakerIconSolid,
    energetic: BoltIconSolid
  }
  return icons[state] || FaceSmileIconSolid
}

// ✅ NUEVA función para colores de estados emocionales
const getEmotionalStateColor = (state) => {
  const colors = {
    happy: 'text-yellow-500',
    excited: 'text-orange-500',
    calm: 'text-blue-500',
    focused: 'text-purple-500',
    supportive: 'text-green-500',
    encouraging: 'text-pink-500',
    thoughtful: 'text-indigo-500',
    energetic: 'text-red-500'
  }
  return colors[state] || 'text-gray-500'
}

// ✅ NUEVA función para formatear nombres de modelos
const formatModelName = (modelName) => {
  // Mapeo de nombres de modelos para mostrar versiones más amigables
  const modelDisplayNames = {
    'gpt-4': 'GPT-4',
    'gpt-4-turbo': 'GPT-4 Turbo',
    'gpt-4o': 'GPT-4o',
    'gpt-4o-mini': 'GPT-4o Mini',
    'gpt-3.5-turbo': 'GPT-3.5',
    'claude-3-sonnet': 'Claude 3',
    'claude-3-haiku': 'Claude 3 Haiku',
    'gemini-pro': 'Gemini Pro'
  }

  return modelDisplayNames[modelName] || modelName
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

/* ✅ REACTION BUTTONS MEJORADOS */
.reaction-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border: 1.5px solid #e5e7eb;
  border-radius: 20px;
  background-color: white;
  color: #4b5563;
  font-size: 0.75rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease-in-out;
  position: relative;
  min-width: 80px;
  justify-content: center;
}

/* Estado inactivo */
.reaction-btn-inactive {
  border-color: #e5e7eb;
  background-color: white;
  color: #6b7280;
}

.reaction-btn-inactive:hover {
  border-color: #d1d5db;
  background-color: #f9fafb;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

/* ✅ Estado activo/presionado */
.reaction-btn-active {
  font-weight: 600;
  transform: translateY(0px);
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.1);
  border-width: 2px;
}

/* Efecto de pulso cuando está activo */
.reaction-btn-active:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15), inset 0 2px 4px rgba(0, 0, 0, 0.1);
}

/* ✅ Checkmark para estados activos - ahora es un icono */
.reaction-checkmark {
  margin-left: 2px;
  animation: checkmark-appear 0.3s ease-out;
  filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.2));
}

@keyframes checkmark-appear {
  0% {
    opacity: 0;
    transform: scale(0.5) rotate(-90deg);
  }
  100% {
    opacity: 1;
    transform: scale(1) rotate(0deg);
  }
}

/* ✅ Colores específicos para cada estado activo */
.bg-blue-100.reaction-btn-active {
  background: linear-gradient(135deg, #dbeafe, #bfdbfe);
  border-color: #3b82f6;
  color: #1d4ed8;
}

.bg-green-100.reaction-btn-active {
  background: linear-gradient(135deg, #dcfce7, #bbf7d0);
  border-color: #10b981;
  color: #065f46;
}

.bg-pink-100.reaction-btn-active {
  background: linear-gradient(135deg, #fce7f3, #fbcfe8);
  border-color: #ec4899;
  color: #be185d;
}

/* ✅ Animación de click */
@keyframes reaction-click {
  0% { transform: scale(1); }
  50% { transform: scale(0.95); }
  100% { transform: scale(1); }
}

.reaction-btn:active {
  animation: reaction-click 0.2s ease-in-out;
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

/* ✅ RESPONSIVE MEJORADO */
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

  /* Botones de reacción más compactos en móvil */
  .reaction-btn {
    padding: 4px 8px;
    font-size: 0.7rem;
    min-width: 70px;
  }

  .reaction-btn span:not(.reaction-checkmark) {
    display: none; /* Ocultar texto en móvil, solo iconos */
  }
}

/* ✅ Efecto hover sutil cuando no está activo */
.reaction-btn-inactive:hover svg {
  transform: scale(1.1);
}

/* ✅ Efecto para iconos cuando está activo */
.reaction-btn-active svg {
  filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.1));
}
</style>
