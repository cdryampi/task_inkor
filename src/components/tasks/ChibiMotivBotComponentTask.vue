<template>
  <div class="bg-gradient-to-br from-primary-50 to-gray-50 rounded-2xl p-6 shadow-lg border border-primary-100 sticky top-8">
    <!-- Header del asistente -->
    <div class="flex items-center gap-4 mb-6 pb-4 border-b border-primary-100">
      <!-- Usar ChibiAvatar -->
      <ChibiAvatar
        :emotional-state="assistantMood"
        size="large"
        :show-emotional-indicator="true"
        :class="[
          'transition-transform duration-300',
          isThinking ? 'animate-pulse' : ''
        ]"
      />

      <div class="flex-1">
        <h3 class="text-lg font-semibold text-gray-800 mb-1">MotivBot</h3>
        <p class="text-sm text-primary-600 font-medium">{{ assistantTitle }}</p>
      </div>

      <!-- Indicador de conexión a OpenAI -->
      <div class="flex flex-col items-center gap-1">
        <div
          :class="[
            'w-2 h-2 rounded-full transition-colors duration-300',
            isConnected ? 'bg-green-400' : 'bg-red-400'
          ]"
        ></div>
        <span class="text-xs text-gray-500">{{ isConnected ? 'Online' : 'Offline' }}</span>
      </div>
    </div>

    <!-- Mensaje contextual -->
    <div class="mb-6">
      <div
        :class="[
          'rounded-xl p-5 transition-all duration-300 border shadow-sm',
          isThinking
            ? 'bg-primary-50 border-primary-200'
            : 'bg-white border-primary-100 shadow-primary-100/20'
        ]"
      >
        <!-- Indicador de pensamiento -->
        <div v-if="isThinking" class="text-center py-2">
          <div class="flex justify-center gap-1 mb-3">
            <span
              v-for="n in 3"
              :key="n"
              :class="[
                'w-1.5 h-1.5 bg-primary-500 rounded-full animate-pulse',
                `animation-delay-${(n-1) * 200}`
              ]"
              :style="{ animationDelay: `${(n-1) * 0.2}s` }"
            ></span>
          </div>
          <p class="text-sm text-primary-600 italic">{{ thinkingMessage }}</p>
        </div>

        <!-- Contenido del mensaje -->
        <div v-else class="space-y-3">
          <p class="text-base leading-relaxed text-gray-700">{{ currentMessage }}</p>

          <!-- ✅ MEJORADO: Tags con colores del estado emocional -->
          <div v-if="currentTags.length > 0" class="flex flex-wrap gap-2">
            <span
              v-for="tag in currentTags"
              :key="tag"
              :class="[
                'text-xs px-3 py-1.5 rounded-full font-medium text-white transition-all duration-200 hover:scale-105 shadow-sm flex items-center gap-1.5',
                getEmotionalStateColorClass(assistantMood)
              ]"
              :title="`Tag: ${getTagLabel(tag)} • Estado: ${assistantMood}`"
            >
              <!-- ✅ NUEVO: Icono del estado emocional en cada tag -->
              <component
                :is="getEmotionalStateIcon(assistantMood)"
                class="w-3 h-3"
              />
              {{ getTagLabel(tag) }}
            </span>
          </div>

          <!-- ✅ SIMPLIFICADO: Fuente del mensaje sin debugging -->
          <div v-if="messageSource" class="flex items-center gap-1 text-xs text-gray-400 italic">
            <component
              :is="getSourceIcon(messageSource)"
              class="w-3 h-3"
            />
            <span>{{ messageSource }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Estado del asistente con iconos mejorados -->
    <div class="flex justify-between pt-4 border-t border-primary-100">
      <div class="flex flex-col items-center gap-1">
        <span class="text-xs text-gray-500 uppercase tracking-wide font-medium flex items-center gap-1">
          <component
            :is="getEmotionalStateIcon(assistantMood)"
            class="w-3 h-3"
            :class="getEmotionalStateColor(assistantMood)"
          />
          Estado:
        </span>
        <span class="text-sm font-semibold text-primary-600">{{ currentState }}</span>
      </div>
      <div class="flex flex-col items-center gap-1">
        <span class="text-xs text-gray-500 uppercase tracking-wide font-medium flex items-center gap-1">
          <EyeIcon class="w-3 h-3" />
          Contexto:
        </span>
        <span class="text-sm font-semibold text-primary-600">{{ contextLevel }}</span>
      </div>
      <div class="flex flex-col items-center gap-1">
        <span class="text-xs text-gray-500 uppercase tracking-wide font-medium flex items-center gap-1">
          <BeakerIcon class="w-3 h-3" />
          Modo:
        </span>
        <span class="text-sm font-semibold text-primary-600">{{ aiMode }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import ChibiAvatar from '@/components/ui/ChibiAvatar.vue'
import {
  EyeIcon,
  BeakerIcon,
  FaceSmileIcon,
  HeartIcon,
  SparklesIcon,
  HandRaisedIcon,
  CloudIcon,
  BoltIcon
} from '@heroicons/vue/24/outline'
import {
  FaceSmileIcon as FaceSmileIconSolid,
  HeartIcon as HeartIconSolid,
  SparklesIcon as SparklesIconSolid,
  EyeIcon as EyeIconSolid,
  HandRaisedIcon as HandRaisedIconSolid,
  BeakerIcon as BeakerIconSolid,
  BoltIcon as BoltIconSolid
} from '@heroicons/vue/24/solid'

// Props
const props = defineProps({
  task: {
    type: Object,
    default: () => ({})
  }
})

// Estado reactivo
const isThinking = ref(false)
const isConnected = ref(true)
const assistantMood = ref('supportive')
const currentState = ref('Listo')
const contextLevel = ref('Alto')
const aiMode = ref('Inteligente')
const currentMessage = ref('¡Hola! Estoy aquí para ayudarte con tus tareas 🚀')
const currentTags = ref([])
const messageSource = ref(null)
const thinkingMessage = ref('Analizando tu tarea...')

// Configuración de la API usando VITE_PROXY_SERVER
const API_BASE_URL = import.meta.env.VITE_PROXY_SERVER || 'http://localhost:3001'

// Computed
const assistantTitle = computed(() => {
  if (currentTags.value.length > 0) {
    return `Asistente de ${currentTags.value[0].charAt(0).toUpperCase() + currentTags.value[0].slice(1)}`
  }
  return 'Asistente de Tareas'
})

// ✅ FUNCIONES DE THINKING ANIMATION
const simulateThinking = (message = 'Pensando...') => {
  isThinking.value = true
  thinkingMessage.value = message
  currentState.value = 'Pensando'
}

const stopThinking = () => {
  isThinking.value = false
  currentState.value = 'Listo'
}

// ✅ MÉTODO PARA REGENERAR MENSAJE (uso interno)
const regenerateMessage = async () => {
  if (!props.task) return
  await updateMotivationalContent()
}

// Métodos de servicios OpenAI
const generateMotivationalMessage = async (taskData = null, customMessage = null) => {
  try {
    const requestBody = {
      message: customMessage || 'Dame un mensaje motivacional para esta tarea',
      context: 'task_assistant',
      taskData: taskData,
      conversationHistory: [],
      task_id: taskData?.id || null
    }

    const response = await fetch(`${API_BASE_URL}/api/motivBotMessagesOpenIA`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody)
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()

    if (data.success && data.data) {
      const messageData = {
        mensaje: data.data.mensaje,
        estado: data.data.estado || 'supportive',
        tags: data.data.tags || [],
        source: getSourceLabel(data.source)
      }

      return messageData
    }

    throw new Error('Respuesta de API inválida')

  } catch (error) {
    console.error('❌ Error generando mensaje:', error)
    isConnected.value = false
    return null
  }
}

// ✅ FUNCIÓN: Convertir source a etiqueta legible
const getSourceLabel = (source) => {
  const sourceLabels = {
    'database': 'Base de datos',
    'generated': 'Generado IA',
    'realtime': 'Tiempo real',
    'fallback': 'Fallback'
  }
  return sourceLabels[source] || source || 'Desconocido'
}

// ✅ FUNCIÓN: Obtener icono según la fuente del mensaje
const getSourceIcon = (source) => {
  const iconMap = {
    'Base de datos': BeakerIcon,
    'Generado IA': SparklesIcon,
    'Tiempo real': BoltIcon,
    'Sistema': EyeIcon,
    'Fallback': CloudIcon
  }
  return iconMap[source] || EyeIcon
}

// ✅ FUNCIÓN: Obtener etiqueta amigable para tags
const getTagLabel = (tag) => {
  const labels = {
    'alta-energia': 'Alta Energía',
    'baja-energia': 'Baja Energía',
    'in-progress': 'En Progreso',
    urgente: 'Urgente',
    importante: 'Importante',
    completado: 'Completado',
    progreso: 'En Progreso',
    pendiente: 'Pendiente',
    trabajo: 'Trabajo',
    personal: 'Personal',
    estudio: 'Estudio',
    hogar: 'Hogar',
    salud: 'Salud',
    social: 'Social',
    rapido: 'Rápido',
    largo: 'Largo Plazo',
    creativo: 'Creativo',
    administrativo: 'Admin',
    reunion: 'Reunión',
    llamada: 'Llamada',
    general: 'General',
    motivacional: 'Motivacional',
    fuerza: 'Fuerza',
    positivo: 'Positivo'
  }

  return labels[tag] || tag.charAt(0).toUpperCase() + tag.slice(1)
}

// ✅ FUNCIÓN: Obtener icono del estado emocional
const getEmotionalStateIcon = (state) => {
  const icons = {
    happy: FaceSmileIconSolid,
    excited: SparklesIconSolid,
    calm: CloudIcon,
    focused: EyeIconSolid,
    supportive: HandRaisedIconSolid,
    encouraging: HeartIconSolid,
    thoughtful: BeakerIconSolid,
    energetic: BoltIconSolid,
    peaceful: CloudIcon,
    confident: EyeIconSolid,
    playful: SparklesIconSolid
  }
  return icons[state] || HandRaisedIconSolid
}

// ✅ FUNCIÓN: Obtener color del estado emocional (para texto/iconos)
const getEmotionalStateColor = (state) => {
  const colors = {
    happy: 'text-yellow-500',
    excited: 'text-orange-500',
    calm: 'text-blue-500',
    focused: 'text-purple-500',
    supportive: 'text-green-500',
    encouraging: 'text-pink-500',
    thoughtful: 'text-indigo-500',
    energetic: 'text-red-500',
    peaceful: 'text-cyan-500',
    confident: 'text-emerald-500',
    playful: 'text-violet-500'
  }
  return colors[state] || 'text-gray-500'
}

// ✅ NUEVA FUNCIÓN: Obtener clase de color de fondo para tags basada en estado emocional
const getEmotionalStateColorClass = (state) => {
  const colorClasses = {
    happy: 'bg-gradient-to-r from-yellow-400 to-yellow-500 hover:from-yellow-500 hover:to-yellow-600',
    excited: 'bg-gradient-to-r from-orange-400 to-orange-500 hover:from-orange-500 hover:to-orange-600',
    calm: 'bg-gradient-to-r from-blue-400 to-blue-500 hover:from-blue-500 hover:to-blue-600',
    focused: 'bg-gradient-to-r from-purple-400 to-purple-500 hover:from-purple-500 hover:to-purple-600',
    supportive: 'bg-gradient-to-r from-green-400 to-green-500 hover:from-green-500 hover:to-green-600',
    encouraging: 'bg-gradient-to-r from-pink-400 to-pink-500 hover:from-pink-500 hover:to-pink-600',
    thoughtful: 'bg-gradient-to-r from-indigo-400 to-indigo-500 hover:from-indigo-500 hover:to-indigo-600',
    energetic: 'bg-gradient-to-r from-red-400 to-red-500 hover:from-red-500 hover:to-red-600',
    peaceful: 'bg-gradient-to-r from-cyan-400 to-cyan-500 hover:from-cyan-500 hover:to-cyan-600',
    confident: 'bg-gradient-to-r from-emerald-400 to-emerald-500 hover:from-emerald-500 hover:to-emerald-600',
    playful: 'bg-gradient-to-r from-violet-400 to-violet-500 hover:from-violet-500 hover:to-violet-600'
  }
  return colorClasses[state] || 'bg-gradient-to-r from-gray-400 to-gray-500 hover:from-gray-500 hover:to-gray-600'
}

// ✅ MÉTODO: Actualizar contenido motivacional
const updateMotivationalContent = async () => {
  if (!props.task) {
    currentMessage.value = '¡Hola! Estoy aquí para ayudarte con tus tareas 🚀'
    assistantMood.value = 'supportive'
    currentTags.value = []
    messageSource.value = null
    contextLevel.value = 'Medio'
    aiMode.value = 'Estándar'
    isConnected.value = true
    return
  }

  simulateThinking('Conectando con OpenAI...')

  try {
    thinkingMessage.value = 'Generando mensaje personalizado...'
    const messageData = await generateMotivationalMessage(props.task)

    if (messageData) {
      currentMessage.value = messageData.mensaje
      assistantMood.value = messageData.estado
      currentTags.value = messageData.tags || []
      messageSource.value = messageData.source
      isConnected.value = true

      // Configuración de contexto basada en source
      if (messageData.source === 'Base de datos') {
        contextLevel.value = 'Alto'
        aiMode.value = 'Optimizado'
      } else if (messageData.source === 'Generado IA') {
        contextLevel.value = 'Alto'
        aiMode.value = 'Creativo'
      } else if (messageData.source === 'Tiempo real') {
        contextLevel.value = 'Máximo'
        aiMode.value = 'Inteligente'
      }
    } else {
      handleFallback()
    }

  } catch (error) {
    console.error('❌ Error actualizando contenido:', error)
    handleFallback()
  } finally {
    stopThinking()
  }
}

// ✅ MÉTODO: Manejo de fallback
const handleFallback = () => {
  currentMessage.value = getFallbackMessage()
  assistantMood.value = 'supportive'
  currentTags.value = getFallbackTags()
  messageSource.value = 'Sistema'
  contextLevel.value = 'Básico'
  aiMode.value = 'Estándar'
  isConnected.value = false
}

// ✅ FUNCIÓN: Tags de fallback basados en la tarea
const getFallbackTags = () => {
  if (!props.task) return ['general']

  const tags = []

  if (props.task.priority === 'high') tags.push('urgente')
  else if (props.task.priority === 'medium') tags.push('importante')

  if (props.task.status === 'completed') tags.push('completado')
  else if (props.task.status === 'in-progress') tags.push('progreso')
  else tags.push('pendiente')

  if (props.task.tags && Array.isArray(props.task.tags)) {
    tags.push(...props.task.tags.slice(0, 2))
  }

  return tags.slice(0, 3)
}

// ✅ FUNCIÓN: Mensaje de fallback contextual
const getFallbackMessage = () => {
  if (!props.task) return '¡Hola! Estoy aquí para ayudarte 🚀'

  const { status, priority, title } = props.task
  const taskName = title ? title.substring(0, 30) : 'esta tarea'

  const fallbackMessages = {
    completed: [
      '¡Excelente trabajo completando esta tarea! 🎉',
      '¡Misión cumplida! Has terminado con éxito 🌟'
    ],
    'high-priority': [
      `¡Alta prioridad! Vamos con todo en "${taskName}" 🔥`,
      '¡Momento de brillar! Esta tarea importante te espera ⚡'
    ],
    'in-progress': [
      `¡Sigue así con "${taskName}"! Vas por buen camino 💪`,
      '¡Excelente progreso! Cada paso te acerca al éxito 🚀'
    ],
    default: [
      `¡Vamos a completar "${taskName}" juntos! 🌟`,
      '¡Tu potencial es ilimitado! Hagamos esto realidad ✨'
    ]
  }

  let messageArray = fallbackMessages.default

  if (status === 'completed') {
    messageArray = fallbackMessages.completed
  } else if (priority === 'high') {
    messageArray = fallbackMessages['high-priority']
  } else if (status === 'in-progress') {
    messageArray = fallbackMessages['in-progress']
  }

  return messageArray[Math.floor(Math.random() * messageArray.length)]
}

// Watchers
watch(() => props.task, (newTask) => {
  if (newTask) {
    updateMotivationalContent()
  }
}, { immediate: true, deep: true })

onMounted(() => {
  updateMotivationalContent()
})
</script>

<style scoped>
/* Animaciones personalizadas */
@keyframes rotate {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.animate-spin {
  animation: rotate 2s linear infinite;
}

/* Delays de animación para puntos de carga */
.animation-delay-0 { animation-delay: 0s; }
.animation-delay-200 { animation-delay: 0.2s; }
.animation-delay-400 { animation-delay: 0.4s; }

/* Transición suave para cambios de estado */
.transition-all {
  transition: all 0.3s ease-in-out;
}
</style>
