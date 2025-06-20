<template>
  <div class="bg-gradient-to-br from-primary-50 to-gray-50 rounded-2xl p-6 shadow-lg border border-primary-100 sticky top-8">
    <!-- Header del asistente -->
    <div class="flex items-center gap-4 mb-6 pb-4 border-b border-primary-100">
      <div class="relative flex-shrink-0">
        <!-- Ring animado -->
        <div
          :class="[
            'absolute -inset-1 rounded-full transition-opacity duration-300',
            'bg-gradient-to-r from-primary-400 via-purple-500 to-blue-500 bg-[length:200%_200%]',
            isThinking ? 'opacity-100 animate-spin' : 'opacity-0'
          ]"
        ></div>

        <!-- Avatar -->
        <img
          :src="currentImage"
          alt="MotivBot"
          :class="[
            'w-15 h-15 rounded-full object-cover bg-white p-1.5 relative z-10 transition-transform duration-300 shadow-md shadow-primary-200',
            isThinking ? 'scale-105 animate-bounce' : ''
          ]"
        />

        <!-- Status indicator -->
        <div
          :class="[
            'absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2 border-white z-20 shadow-sm',
            {
              'bg-blue-500': assistantMood === 'focused',
              'bg-primary-500': assistantMood === 'happy',
              'bg-amber-500': assistantMood === 'excited',
              'bg-red-500': assistantMood === 'thoughtful',
              'bg-purple-500': assistantMood === 'calm',
              'bg-purple-400': assistantMood === 'peaceful',
              'bg-cyan-700': assistantMood === 'confident',
              'bg-orange-500': assistantMood === 'playful',
            }
          ]"
        ></div>
      </div>

      <div class="flex-1">
        <h3 class="text-lg font-semibold text-gray-800 mb-1">MotivBot</h3>
        <p class="text-sm text-primary-600 font-medium">Asistente de Tareas</p>
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
          <p class="text-sm text-primary-600 italic">Analizando tu tarea...</p>
        </div>

        <!-- Contenido del mensaje -->
        <div v-else class="space-y-3">
          <p class="text-base leading-relaxed text-gray-700">{{ currentMessage }}</p>

          <!-- Tags -->
          <div v-if="detectedTags.length > 0" class="flex flex-wrap gap-2">
            <span
              v-for="tag in detectedTags"
              :key="tag"
              :class="[
                'text-xs px-3 py-1 rounded-full font-medium text-white',
                {
                  'bg-red-500': tag === 'urgent',
                  'bg-blue-500': tag === 'meeting',
                  'bg-green-500': tag === 'call',
                  'bg-amber-500': tag === 'email',
                  'bg-purple-500': tag === 'coding',
                  'bg-primary-500': tag === 'design',
                  'bg-primary-400': tag === 'review',
                  'bg-green-500': tag === 'completed',
                  'bg-blue-500': tag === 'progress',
                  'bg-gray-400': tag === 'pending'
                }
              ]"
            >
              {{ getTagLabel(tag) }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Estado del asistente -->
    <div class="flex justify-between pt-4 border-t border-primary-100">
      <div class="flex flex-col items-center gap-1">
        <span class="text-xs text-gray-500 uppercase tracking-wide font-medium">Estado:</span>
        <span class="text-sm font-semibold text-primary-600">{{ currentState }}</span>
      </div>
      <div class="flex flex-col items-center gap-1">
        <span class="text-xs text-gray-500 uppercase tracking-wide font-medium">Contexto:</span>
        <span class="text-sm font-semibold text-primary-600">{{ contextLevel }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useChibiStates } from '@/composables/useChibiStates'

// Props
const props = defineProps({
  task: {
    type: Object,
    default: () => ({})
  }
})

// Composables
const { currentImage, setChibiState } = useChibiStates()

// Estado reactivo
const isThinking = ref(false)
const assistantMood = ref('focused')
const currentState = ref('Listo')
const contextLevel = ref('Alto')

// Mensajes estáticos basados en la tarea
const staticMessages = {
  // Mensajes por estado
  completed: [
    { mensaje: '¡Increíble trabajo! Has completado esta tarea con éxito 🎉', estado: 'happy' },
    { mensaje: '¡Tarea completada! Eres imparable 💪✨', estado: 'excited' },
    { mensaje: '¡Excelente! Una tarea menos en tu lista 🌟', estado: 'happy' }
  ],
  'in-progress': [
    { mensaje: '¡Vas por buen camino! Mantén el momentum 🚀', estado: 'focused' },
    { mensaje: '¡Sigue así! Estás haciendo un gran progreso 💪', estado: 'energetic' },
    { mensaje: 'Perfecto, mantienes el ritmo constante ⚡', estado: 'focused' }
  ],
  pending: [
    { mensaje: '¡Es hora de brillar! Comencemos con esta tarea 🌟', estado: 'energetic' },
    { mensaje: '¡Nueva aventura! ¿Por dónde empezamos? 🚀', estado: 'excited' },
    { mensaje: 'Esta tarea tiene potencial. ¡Vamos a por ella! 💫', estado: 'happy' }
  ],
  'on-hold': [
    { mensaje: 'Está en pausa, pero no olvidada. ¿La retomamos? 🤔', estado: 'calm' },
    { mensaje: 'Pausada pero no perdida. Todo a su tiempo ⏸️', estado: 'peaceful' },
    { mensaje: 'A veces una pausa es estratégica 🧘‍♂️', estado: 'calm' }
  ],

  // Mensajes por prioridad
  high: [
    { mensaje: '¡ALTA PRIORIDAD! Esta tarea necesita tu atención inmediata 🔥', estado: 'energetic' },
    { mensaje: '¡Código rojo! Esta tarea es súper importante ⚡', estado: 'focused' },
    { mensaje: '¡Misión crítica! Todo tu enfoque aquí 🎯', estado: 'energetic' }
  ],
  medium: [
    { mensaje: 'Prioridad media, pero igual de importante 📋', estado: 'focused' },
    { mensaje: 'En su momento justo. Organizemos bien el tiempo ⏰', estado: 'calm' },
    { mensaje: 'Perfecta para cuando termines las urgentes 📝', estado: 'peaceful' }
  ],
  low: [
    { mensaje: 'Sin prisa pero sin pausa. Todo suma 🌱', estado: 'calm' },
    { mensaje: 'Cada pequeño paso cuenta. ¡Adelante! 🚶‍♂️', estado: 'peaceful' },
    { mensaje: 'Prioridad baja, impacto constante 📈', estado: 'calm' }
  ],

  // Mensajes por deadline
  overdue: [
    { mensaje: '⚠️ ¡Ups! Esta tarea necesita atención urgente', estado: 'focused' },
    { mensaje: '🚨 ¡Hora de ponerse las pilas! No es tarde aún', estado: 'energetic' },
    { mensaje: '⏰ ¡Vamos! Aún se puede recuperar el tiempo', estado: 'focused' }
  ],
  today: [
    { mensaje: '⏰ ¡HOY es el día! ¡Dale máxima prioridad!', estado: 'energetic' },
    { mensaje: '🎯 ¡Enfoque total! Esta tarea vence hoy', estado: 'focused' },
    { mensaje: '🔥 ¡Último día! ¡Tú puedes con esto!', estado: 'energetic' }
  ],
  soon: [
    { mensaje: '⏳ Se acerca la fecha límite. ¡Preparémonos! 💪', estado: 'focused' },
    { mensaje: '📅 Quedan pocos días. ¡Organicemos el tiempo!', estado: 'calm' },
    { mensaje: '⚡ ¡Tiempo de acción! La fecha se acerca', estado: 'energetic' }
  ],

  // Mensajes genéricos
  default: [
    { mensaje: '¡Hola! Estoy aquí para motivarte con tus tareas 🚀', estado: 'happy' },
    { mensaje: '¡Listos para ser productivos! ¿Empezamos? ✨', estado: 'excited' },
    { mensaje: '¡Otro día, otra oportunidad de brillar! 🌟', estado: 'energetic' }
  ]
}

// Mensaje contextual actual
const currentMessage = ref('¡Hola! Estoy aquí para ayudarte con tus tareas 🚀')

// Tags detectados basados en el contenido de la tarea
const detectedTags = computed(() => {
  if (!props.task) return []

  const tags = []
  const { title, description, status, priority, due_date } = props.task
  const content = `${title || ''} ${description || ''}`.toLowerCase()

  // Detectar tags por contenido
  if (content.includes('urgente') || priority === 'high') tags.push('urgent')
  if (content.includes('reunión') || content.includes('meeting')) tags.push('meeting')
  if (content.includes('llamada') || content.includes('call')) tags.push('call')
  if (content.includes('email') || content.includes('correo')) tags.push('email')
  if (content.includes('código') || content.includes('programar')) tags.push('coding')
  if (content.includes('diseño') || content.includes('design')) tags.push('design')
  if (content.includes('revisar') || content.includes('review')) tags.push('review')

  // Tags por estado
  if (status === 'completed') tags.push('completed')
  if (status === 'in-progress') tags.push('progress')
  if (status === 'pending') tags.push('pending')

  return tags.slice(0, 3) // Máximo 3 tags
})

// Métodos
const getDaysUntilDue = (dueDate) => {
  const now = new Date()
  const due = new Date(dueDate)
  return Math.ceil((due - now) / (1000 * 60 * 60 * 24))
}

const getTagLabel = (tag) => {
  const labels = {
    urgent: 'Urgente',
    meeting: 'Reunión',
    call: 'Llamada',
    email: 'Email',
    coding: 'Código',
    design: 'Diseño',
    review: 'Revisión',
    completed: 'Completado',
    progress: 'En Progreso',
    pending: 'Pendiente'
  }
  return labels[tag] || tag
}

const simulateThinking = () => {
  isThinking.value = true
  currentState.value = 'Analizando'
  setTimeout(() => {
    isThinking.value = false
    currentState.value = 'Activo'
  }, 1500)
}

// Obtener mensaje contextual basado en la tarea
const getContextualMessage = () => {
  if (!props.task) {
    const messages = staticMessages.default
    return messages[Math.floor(Math.random() * messages.length)]
  }

  const { status, priority, due_date } = props.task

  // Prioridad por deadline
  if (due_date) {
    const daysUntilDue = getDaysUntilDue(due_date)
    if (daysUntilDue < 0 && staticMessages.overdue) {
      const messages = staticMessages.overdue
      return messages[Math.floor(Math.random() * messages.length)]
    }
    if (daysUntilDue === 0 && staticMessages.today) {
      const messages = staticMessages.today
      return messages[Math.floor(Math.random() * messages.length)]
    }
    if (daysUntilDue <= 2 && staticMessages.soon) {
      const messages = staticMessages.soon
      return messages[Math.floor(Math.random() * messages.length)]
    }
  }

  // Por estado
  if (status && staticMessages[status]) {
    const messages = staticMessages[status]
    return messages[Math.floor(Math.random() * messages.length)]
  }

  // Por prioridad
  if (priority && staticMessages[priority]) {
    const messages = staticMessages[priority]
    return messages[Math.floor(Math.random() * messages.length)]
  }

  // Mensaje por defecto
  const messages = staticMessages.default
  return messages[Math.floor(Math.random() * messages.length)]
}

// Actualizar mensaje y estado
const updateMessage = () => {
  simulateThinking()

  setTimeout(() => {
    const messageData = getContextualMessage()
    currentMessage.value = messageData.mensaje
    assistantMood.value = messageData.estado
    setChibiState(messageData.estado)

    // Actualizar contexto
    contextLevel.value = props.task ? 'Alto' : 'Medio'

    console.log('💬 MotivBot - Mensaje actualizado:', {
      mensaje: messageData.mensaje,
      estado: messageData.estado,
      task: props.task?.title || 'Sin tarea'
    })
  }, 1500)
}

// Watchers
watch(() => props.task, (newTask) => {
  if (newTask) {
    console.log('🔄 MotivBot - Nueva tarea detectada:', newTask.title)
    updateMessage()
  }
}, { immediate: true, deep: true })

onMounted(() => {
  console.log('🚀 MotivBot - Componente montado')
  updateMessage()

  // Cambiar mensaje cada 8 segundos para ver los cambios
  setInterval(() => {
    updateMessage()
  }, 8000)
})
</script>

<style scoped>
/* Solo estilos que no se pueden hacer con Tailwind */
@keyframes rotate {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.animate-spin {
  animation: rotate 2s linear infinite;
}

/* Clases personalizadas para delays de animación */
.animation-delay-0 { animation-delay: 0s; }
.animation-delay-200 { animation-delay: 0.2s; }
.animation-delay-400 { animation-delay: 0.4s; }


</style>
