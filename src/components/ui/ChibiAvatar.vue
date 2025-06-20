<template>
  <div class="chibi-avatar" :class="avatarClasses">
    <div class="relative w-full h-full flex items-center justify-center">
      <img
        :src="getChibiImage()"
        :alt="`MotivBot ${emotionalState}`"
        class="w-full h-full object-cover rounded-full transition-transform duration-300 ease-in-out"
        @error="handleImageError"
      />
      <div
        v-if="showEmotionalIndicator"
        class="absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full flex items-center justify-center border-2 border-white shadow-sm"
        :class="indicatorClasses"
      >
        <component :is="getEmotionIcon()" class="w-3 h-3" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import {
  HeartIcon,
  SparklesIcon,
  LightBulbIcon,
  BoltIcon,
  HandThumbUpIcon,
  FaceSmileIcon,
  CloudIcon,
  FireIcon
} from '@heroicons/vue/24/solid'

const props = defineProps({
  emotionalState: {
    type: String,
    default: 'supportive'
  },
  size: {
    type: String,
    default: 'medium' // small, medium, large
  },
  showEmotionalIndicator: {
    type: Boolean,
    default: true
  }
})

const avatarClasses = computed(() => {
  const baseClasses = [
    'relative flex items-center justify-center rounded-full overflow-hidden',
    'transition-all duration-300 ease-in-out',
    'hover:scale-105 hover:shadow-lg hover:brightness-105',
    'focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2'
  ]

  // Clases de tamaño
  const sizeClasses = {
    small: ['w-10 h-10', 'md:w-8 md:h-8'], // Responsive para móvil
    medium: ['w-12 h-12', 'md:w-10 md:h-10'],
    large: ['w-15 h-15', 'md:w-15 md:h-15']
  }

  // Clases de estado emocional con gradientes Tailwind
  const emotionClasses = {
    happy: [
      'bg-gradient-to-br from-yellow-200 to-yellow-300',
      'ring-2 ring-yellow-400'
    ],
    excited: [
      'bg-gradient-to-br from-orange-200 to-orange-300',
      'ring-2 ring-orange-400'
    ],
    calm: [
      'bg-gradient-to-br from-blue-200 to-blue-300',
      'ring-2 ring-blue-400'
    ],
    focused: [
      'bg-gradient-to-br from-purple-200 to-purple-300',
      'ring-2 ring-purple-400'
    ],
    supportive: [
      'bg-gradient-to-br from-green-200 to-green-300',
      'ring-2 ring-green-400'
    ],
    encouraging: [
      'bg-gradient-to-br from-pink-200 to-pink-300',
      'ring-2 ring-pink-400'
    ],
    thoughtful: [
      'bg-gradient-to-br from-indigo-200 to-indigo-300',
      'ring-2 ring-indigo-400'
    ],
    energetic: [
      'bg-gradient-to-br from-red-200 to-red-300',
      'ring-2 ring-red-400'
    ]
  }

  return [
    ...baseClasses,
    ...(sizeClasses[props.size] || sizeClasses.medium),
    ...(emotionClasses[props.emotionalState] || emotionClasses.supportive)
  ]
})

const indicatorClasses = computed(() => {
  const stateClasses = {
    happy: 'bg-yellow-400 text-yellow-800',
    excited: 'bg-orange-400 text-orange-800',
    calm: 'bg-blue-400 text-blue-800',
    focused: 'bg-purple-400 text-purple-800',
    supportive: 'bg-green-400 text-green-800',
    encouraging: 'bg-pink-400 text-pink-800',
    thoughtful: 'bg-indigo-400 text-indigo-800',
    energetic: 'bg-red-400 text-red-800'
  }

  return stateClasses[props.emotionalState] || stateClasses.supportive
})

const getChibiImage = () => {
  const imageMap = {
    happy: '/images/chibi/happy.png',
    excited: '/images/chibi/excited.png',
    calm: '/images/chibi/calm.png',
    focused: '/images/chibi/focused.png',
    supportive: '/images/chibi/supportive.png',
    encouraging: '/images/chibi/encouraging.png',
    thoughtful: '/images/chibi/thoughtful.png',
    energetic: '/images/chibi/energetic.png'
  }

  return imageMap[props.emotionalState] || imageMap.supportive
}

const getEmotionIcon = () => {
  const iconMap = {
    happy: FaceSmileIcon,
    excited: FireIcon,
    calm: CloudIcon,
    focused: LightBulbIcon,
    supportive: HandThumbUpIcon,
    encouraging: HeartIcon,
    thoughtful: SparklesIcon,
    energetic: BoltIcon
  }

  return iconMap[props.emotionalState] || HandThumbUpIcon
}

const handleImageError = (event) => {
  event.target.src = '/images/chibi/default.png'
}
</script>

<style scoped>
/* Solo animaciones personalizadas que Tailwind no tiene */
.chibi-avatar:hover img {
  transform: scale(1.1);
}

/* Animación para cambios de estado */
@keyframes pulse-chibi {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

.chibi-avatar.state-changed {
  animation: pulse-chibi 0.6s ease-in-out;
}

/* Animación de latido para estado encouraging */
@keyframes heartbeat {
  0%, 100% { transform: scale(1); }
  14% { transform: scale(1.1); }
  28% { transform: scale(1); }
  42% { transform: scale(1.1); }
  70% { transform: scale(1); }
}

.chibi-avatar:hover .bg-pink-400 {
  animation: heartbeat 1.5s ease-in-out infinite;
}

/* Efecto de pulso para estado energético */
.chibi-avatar:hover.ring-red-400 {
  animation: pulse-chibi 0.8s ease-in-out infinite;
}

/* Transición suave para cambios de estado emocional */
.emotion-transition {
  transition: all 0.5s ease-in-out;
}
</style>
