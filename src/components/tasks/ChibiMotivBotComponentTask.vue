<template>
  <div class="bg-gradient-to-br from-primary-50 to-gray-50 rounded-2xl p-6 shadow-lg border border-primary-100 sticky top-8">
    <!-- Header del asistente -->
    <div class="flex items-center gap-4 mb-6 pb-4 border-b border-primary-100">
      <!-- Usar ChibiAvatar en lugar del avatar manual -->
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
        :class=" [
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
              :class=" [
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

          <!-- Tags dinámicos desde OpenAI -->
          <div v-if="currentTags.length > 0" class="flex flex-wrap gap-2">
            <span
              v-for="tag in currentTags"
              :key="tag"
              :class=" [
                'text-xs px-3 py-1 rounded-full font-medium text-white transition-colors duration-200',
                getTagColor(tag)
              ]"
            >
              {{ getTagLabel(tag) }}
            </span>
          </div>

          <!-- Fuente del mensaje -->
          <div v-if="messageSource" class="text-xs text-gray-400 italic">
            Fuente: {{ messageSource }}
          </div>
        </div>
      </div>
    </div>

    <!-- Estado del asistente con iconos mejorados -->
    <div class="flex justify-between pt-4 border-t border-primary-100">
      <div class="flex flex-col items-center gap-1">
        <span class="text-xs text-gray-500 uppercase tracking-wide font-medium flex items-center gap-1">
          <!-- ✅ Añadir icono de estado -->
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

    <!-- Botón de regenerar mensaje (solo en desarrollo) -->
    <div v-if="isDevelopment" class="mt-4 pt-4 border-t border-primary-100">
      <button
        @click="regenerateMessage"
        :disabled="isThinking"
        class="w-full px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
      >
        {{ isThinking ? 'Generando...' : 'Regenerar Mensaje' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import ChibiAvatar from '@/components/ui/ChibiAvatar.vue'
import {
  // ✅ Importar iconos para usar en el componente
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

const isDevelopment = computed(() => {
  return import.meta.env.DEV
})

// Métodos de servicios OpenAI
const generateTaskTags = async (taskId) => {
  if (!taskId) return []

  try {
    console.log(`🏷️ Generando tags para tarea ID: ${taskId}`)
    console.log(`🔗 API URL: ${API_BASE_URL}/api/motivBotTaskAddTags`)

    const response = await fetch(`${API_BASE_URL}/api/motivBotTaskAddTags`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        task_id: taskId
      })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()

    if (data.success) {
      console.log('✅ Tags generados:', data.data.generated_tags || data.data.existing_tags)
      return data.data.generated_tags || data.data.existing_tags || []
    }

    return []
  } catch (error) {
    console.error('❌ Error generando tags:', error)
    isConnected.value = false
    return []
  }
}

const generateMotivationalMessage = async (taskData = null, customMessage = null) => {
  try {
    console.log('🤖 Generando mensaje motivacional con OpenAI...')
    console.log(`🔗 API URL: ${API_BASE_URL}/api/motivBotMessagesOpenIA`)

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

    if (data.success) {
      console.log('✅ Mensaje generado:', data)

      // Manejar diferentes fuentes de respuesta
      if (data.source === 'database' && Array.isArray(data.data)) {
        // Mensajes de base de datos
        const randomMessage = data.data[Math.floor(Math.random() * data.data.length)]
        return {
          mensaje: randomMessage.mensaje,
          estado: randomMessage.estado,
          tags: randomMessage.tags || [],
          source: 'Base de datos'
        }
      } else if (data.source === 'realtime' || data.source === 'generated') {
        // Mensaje en tiempo real
        return {
          mensaje: data.data.mensaje,
          estado: data.data.estado,
          tags: data.data.tags || [],
          source: data.source === 'realtime' ? 'Tiempo real' : 'Generado'
        }
      }
    }

    return null
  } catch (error) {
    console.error('❌ Error generando mensaje:', error)
    isConnected.value = false
    return null
  }
}

// Métodos de utilidad
const getTagColor = (tag) => {
  const colorMap = {
    // Colores por tipo de tag
    urgente: 'bg-red-500',
    importante: 'bg-orange-500',
    trabajo: 'bg-blue-500',
    personal: 'bg-green-500',
    reunion: 'bg-purple-500',
    llamada: 'bg-cyan-500',
    email: 'bg-amber-500',
    coding: 'bg-indigo-500',
    design: 'bg-pink-500',
    review: 'bg-gray-500',
    completed: 'bg-green-600',
    progress: 'bg-blue-600',
    pending: 'bg-gray-400',
    // Colores por tecnología
    python: 'bg-yellow-600',
    javascript: 'bg-yellow-500',
    vuejs: 'bg-green-600',
    react: 'bg-blue-400',
    nodejs: 'bg-green-700',
    html: 'bg-orange-600',
    css: 'bg-blue-500',
    tailwind: 'bg-teal-500'
  }

  return colorMap[tag.toLowerCase()] || 'bg-primary-500'
}

const getTagLabel = (tag) => {
  const labelMap = {
    urgente: 'Urgente',
    importante: 'Importante',
    trabajo: 'Trabajo',
    personal: 'Personal',
    reunion: 'Reunión',
    llamada: 'Llamada',
    email: 'Email',
    coding: 'Código',
    design: 'Diseño',
    review: 'Revisión',
    completed: 'Completado',
    progress: 'En Progreso',
    pending: 'Pendiente',
    python: 'Python',
    javascript: 'JavaScript',
    vuejs: 'Vue.js',
    react: 'React',
    nodejs: 'Node.js',
    html: 'HTML',
    css: 'CSS',
    tailwind: 'Tailwind'
  }

  return labelMap[tag.toLowerCase()] || tag.charAt(0).toUpperCase() + tag.slice(1)
}

const simulateThinking = (message = 'Analizando tu tarea...') => {
  isThinking.value = true
  thinkingMessage.value = message
  currentState.value = 'Analizando'
}

const stopThinking = () => {
  isThinking.value = false
  currentState.value = 'Activo'
  isConnected.value = true
}

// Método principal para actualizar contenido
const updateMotivationalContent = async () => {
  if (!props.task) {
    // Sin tarea, mostrar mensaje genérico
    currentMessage.value = '¡Hola! Estoy aquí para ayudarte con tus tareas 🚀'
    assistantMood.value = 'supportive'
    currentTags.value = []
    messageSource.value = null
    contextLevel.value = 'Medio'
    aiMode.value = 'Estándar'
    return
  }

  simulateThinking('Conectando con OpenAI...')

  try {
    // Paso 1: Generar/obtener tags para la tarea
    const tags = await generateTaskTags(props.task.id)
    currentTags.value = tags

    // Paso 2: Generar mensaje motivacional
    thinkingMessage.value = 'Generando mensaje personalizado...'
    const messageData = await generateMotivationalMessage(props.task)

    if (messageData) {
      currentMessage.value = messageData.mensaje
      assistantMood.value = messageData.estado
      messageSource.value = messageData.source

      // Combinar tags de tarea con tags de mensaje
      const allTags = [...new Set([...currentTags.value, ...messageData.tags])]
      currentTags.value = allTags.slice(0, 5) // Máximo 5 tags

      contextLevel.value = 'Alto'
      aiMode.value = 'Inteligente'
    } else {
      // Fallback a mensaje estático
      currentMessage.value = getFallbackMessage()
      assistantMood.value = 'supportive'
      messageSource.value = 'Fallback'
      aiMode.value = 'Estándar'
    }

    console.log('💬 MotivBot - Contenido actualizado:', {
      mensaje: currentMessage.value,
      estado: assistantMood.value,
      tags: currentTags.value,
      fuente: messageSource.value,
      task: props.task?.title || 'Sin tarea'
    })

  } catch (error) {
    console.error('❌ Error actualizando contenido:', error)
    currentMessage.value = getFallbackMessage()
    assistantMood.value = 'supportive'
    messageSource.value = 'Error'
    isConnected.value = false
  } finally {
    stopThinking()
  }
}

// Mensaje de fallback si falla OpenAI
const getFallbackMessage = () => {
  if (!props.task) return '¡Hola! Estoy aquí para ayudarte 🚀'

  const { status, priority } = props.task

  if (status === 'completed') return '¡Excelente trabajo! Tarea completada 🎉'
  if (priority === 'high') return '¡Alta prioridad! Vamos con todo 🔥'
  if (status === 'in-progress') return '¡Sigue así! Vas por buen camino 💪'

  return '¡Vamos a completar esta tarea juntos! 🌟'
}

// Método para regenerar mensaje (solo desarrollo)
const regenerateMessage = () => {
  updateMotivationalContent()
}

// Función para obtener icono del estado emocional
const getEmotionalStateIcon = (state) => {
  const icons = {
    happy: FaceSmileIconSolid,
    excited: SparklesIconSolid,
    calm: CloudIcon,
    focused: EyeIconSolid,
    supportive: HandRaisedIconSolid,
    encouraging: HeartIconSolid,
    thoughtful: BeakerIconSolid,
    energetic: BoltIconSolid
  }
  return icons[state] || FaceSmileIconSolid
}

// Función para obtener color del estado emocional
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

// Watchers
watch(() => props.task, (newTask) => {
  if (newTask) {
    console.log('🔄 MotivBot - Nueva tarea detectada:', newTask.title)
    updateMotivationalContent()
  }
}, { immediate: true, deep: true })

onMounted(() => {
  console.log('🚀 MotivBot - Componente montado con integración OpenAI')
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
