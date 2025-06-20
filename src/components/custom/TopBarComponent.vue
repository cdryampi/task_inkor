<template>
  <div class="topbar-wrapper">
    <div class="topbar-container">
      <!-- Chibi Avatar Component -->
      <div class="chibi-section">
        <div class="chibi-container" :class="{ 'animate-pulse': isChangingMessage }">
          <div class="avatar-ring" :class="{ 'active': isChangingMessage }"></div>
          <ChibiAvatar
            :emotional-state="estado"
            size="large"
            :show-emotional-indicator="true"
            :class="{ 'talking': isChangingMessage }"
            @click="cambiarMensaje"
            class="cursor-pointer"
          />
        </div>
      </div>

      <!-- Mensaje en burbuja moderna -->
      <div class="message-section">
        <div class="speech-bubble" :class="{ 'typing': isChangingMessage }">
          <div class="bubble-tail"></div>
          <div class="bubble-content">
            <div v-if="isChangingMessage" class="typing-animation">
              <div class="typing-dots">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
            <p v-else class="message-text">{{ mensajeActual }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import ChibiAvatar from '../ui/ChibiAvatar.vue'
import { useSupabase } from '@/hooks/supabase'

const { getRandomMessages } = useSupabase()

const mensaje = ref('')
const estado = ref('supportive')
const isChangingMessage = ref(false)
const mensajesCacheados = ref([])

const mensajeActual = computed(() => {
  return mensaje.value
})

// Función para cargar mensajes desde Supabase
const cargarMensajes = async () => {
  try {
    console.log('🔄 TopBar - Cargando mensajes desde Supabase...')
    const mensajes = await getRandomMessages(20)

    if (mensajes && mensajes.length > 0) {
      mensajesCacheados.value = mensajes
      console.log('✅ TopBar - Mensajes cargados:', mensajes.length)
    } else {
      console.warn('⚠️ TopBar - No se encontraron mensajes, usando fallback')
      // Mensajes de respaldo mapeados a estados emocionales del ChibiAvatar
      mensajesCacheados.value = [
        { mensaje: '¡Hoy es un gran día para conquistar el mundo! 🌟', estado: 'excited' },
        { mensaje: 'Respira profundo, todo va a estar bien 💙', estado: 'calm' },
        { mensaje: '¡Eres más fuerte de lo que crees! 💪', estado: 'encouraging' },
        { mensaje: 'Mantén el enfoque, vas genial 🎯', estado: 'focused' },
        { mensaje: 'Cada pequeño paso cuenta 🚶‍♀️', estado: 'supportive' },
        { mensaje: '¡Sonríe, todo fluye mejor! 😊', estado: 'happy' },
        { mensaje: 'La energía positiva es contagiosa ⚡', estado: 'energetic' },
        { mensaje: 'Reflexiona y encuentra tu camino 🤔', estado: 'thoughtful' }
      ]
    }
  } catch (error) {
    console.error('❌ TopBar - Error cargando mensajes:', error)
    // Usar mensajes de respaldo en caso de error
    mensajesCacheados.value = [
      { mensaje: '¡Hoy es un gran día para conquistar el mundo! 🌟', estado: 'excited' },
      { mensaje: 'Respira profundo, todo va a estar bien 💙', estado: 'calm' },
      { mensaje: '¡Eres más fuerte de lo que crees! 💪', estado: 'encouraging' },
      { mensaje: 'Mantén el enfoque, vas genial 🎯', estado: 'focused' },
      { mensaje: 'Cada pequeño paso cuenta 🚶‍♀️', estado: 'supportive' },
      { mensaje: '¡Sonríe, todo fluye mejor! 😊', estado: 'happy' },
      { mensaje: 'La energía positiva es contagiosa ⚡', estado: 'energetic' },
      { mensaje: 'Reflexiona y encuentra tu camino 🤔', estado: 'thoughtful' }
    ]
  }
}

const cambiarMensaje = async () => {
  if (mensajesCacheados.value.length === 0) {
    console.warn('⚠️ TopBar - No hay mensajes cacheados, cargando...')
    await cargarMensajes()
  }

  isChangingMessage.value = true

  // Simular tiempo de "pensamiento" del avatar
  await new Promise(resolve => setTimeout(resolve, 1500))

  if (mensajesCacheados.value.length > 0) {
    const mensajeRandom = mensajesCacheados.value[Math.floor(Math.random() * mensajesCacheados.value.length)]
    mensaje.value = mensajeRandom.mensaje
    estado.value = mensajeRandom.estado

    console.log('💬 TopBar - Mensaje mostrado:', {
      mensaje: mensajeRandom.mensaje,
      estado: mensajeRandom.estado
    })
  }

  setTimeout(() => {
    isChangingMessage.value = false
  }, 800)
}

// Función para recargar mensajes (se puede usar para refrescar la caché)
const recargarMensajes = async () => {
  if (isChangingMessage.value) return

  console.log('🔄 TopBar - Recargando mensajes...')
  await cargarMensajes()
  await cambiarMensaje()
}

onMounted(async () => {
  await cargarMensajes()
  // Mostrar primer mensaje después de un momento
  setTimeout(() => {
    cambiarMensaje()
  }, 1000)
})

// Cambiar mensaje cada 15 segundos
setInterval(() => {
  cambiarMensaje()
}, 15000)

// Recargar mensajes cada 5 minutos para obtener contenido fresco
setInterval(() => {
  recargarMensajes()
}, 300000) // 5 minutos
</script>

<style scoped>
.topbar-wrapper {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 1rem 0;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  position: relative;
  overflow: hidden;
}

.topbar-wrapper::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.05'%3E%3Ccircle cx='30' cy='30' r='2'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E") repeat;
  opacity: 0.3;
}

.topbar-container {
  display: flex;
  align-items: center;
  justify-content: center;
  max-width: 900px;
  margin: 0 auto;
  padding: 0 2rem;
  position: relative;
  z-index: 1;
  gap: 2rem;
}

.chibi-section {
  flex-shrink: 0;
}

.chibi-container {
  position: relative;
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.avatar-ring {
  position: absolute;
  inset: -4px;
  border-radius: 50%;
  background: linear-gradient(45deg, #ff6b6b, #4ecdc4, #45b7d1, #96ceb4);
  background-size: 400% 400%;
  animation: gradientShift 3s ease-in-out infinite;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.avatar-ring.active {
  opacity: 1;
  animation: gradientShift 1s ease-in-out infinite, pulse 1s ease-in-out infinite;
}

/* Sobrescribir estilos del ChibiAvatar para el TopBar */
.chibi-container :deep(.chibi-avatar) {
  width: 80px !important;
  height: 80px !important;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
  border: 4px solid white;
  transition: transform 0.3s ease;
}

.chibi-container.talking :deep(.chibi-avatar) {
  transform: scale(1.05) rotate(2deg);
  animation: talk 0.6s ease-in-out infinite alternate;
}

.message-section {
  flex: 1;
  max-width: 500px;
}

.speech-bubble {
  background: white;
  border-radius: 20px;
  padding: 1.5rem 2rem;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  position: relative;
  transform: translateY(0);
  transition: all 0.4s ease;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.speech-bubble.typing {
  background: #f8f9fa;
  transform: translateY(-2px);
  box-shadow: 0 15px 40px rgba(0, 0, 0, 0.15);
}

.bubble-tail {
  position: absolute;
  left: -15px;
  top: 50%;
  transform: translateY(-50%);
  width: 0;
  height: 0;
  border-top: 15px solid transparent;
  border-bottom: 15px solid transparent;
  border-right: 15px solid white;
}

.speech-bubble.typing .bubble-tail {
  border-right-color: #f8f9fa;
}

.bubble-content {
  min-height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.message-text {
  font-size: 1.1rem;
  font-weight: 500;
  color: #2d3748;
  text-align: center;
  line-height: 1.6;
  margin: 0;
  animation: fadeInUp 0.6s ease-out;
}

.typing-animation {
  display: flex;
  align-items: center;
  justify-content: center;
}

.typing-dots {
  display: flex;
  gap: 6px;
}

.typing-dots span {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #667eea;
  animation: typing 1.4s infinite ease-in-out;
}

.typing-dots span:nth-child(1) { animation-delay: 0s; }
.typing-dots span:nth-child(2) { animation-delay: 0.2s; }
.typing-dots span:nth-child(3) { animation-delay: 0.4s; }

@keyframes gradientShift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

@keyframes talk {
  0% { transform: scale(1.05) rotate(1deg); }
  100% { transform: scale(1.05) rotate(-1deg); }
}

@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}

@keyframes typing {
  0%, 60%, 100% {
    transform: translateY(0);
    opacity: 0.4;
  }
  30% {
    transform: translateY(-10px);
    opacity: 1;
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  .topbar-wrapper {
    background: linear-gradient(135deg, #1a202c 0%, #2d3748 100%);
  }

  .speech-bubble {
    background: #2d3748;
    color: white;
  }

  .speech-bubble.typing {
    background: #4a5568;
  }

  .bubble-tail {
    border-right-color: #2d3748;
  }

  .speech-bubble.typing .bubble-tail {
    border-right-color: #4a5568;
  }

  .message-text {
    color: #e2e8f0;
  }
}

/* Responsive */
@media (max-width: 768px) {
  .topbar-container {
    flex-direction: column;
    text-align: center;
    gap: 1rem;
  }

  .bubble-tail {
    left: 50%;
    top: -15px;
    transform: translateX(-50%);
    border-left: 15px solid transparent;
    border-right: 15px solid transparent;
    border-bottom: 15px solid white;
    border-top: none;
  }

  .speech-bubble.typing .bubble-tail {
    border-bottom-color: #f8f9fa;
  }

  .chibi-container {
    width: 70px;
    height: 70px;
  }

  .chibi-container :deep(.chibi-avatar) {
    width: 70px !important;
    height: 70px !important;
  }
}
</style>
