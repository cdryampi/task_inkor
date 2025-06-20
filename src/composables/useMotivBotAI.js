import { ref } from 'vue'

const isLoading = ref(false)
const error = ref(null)

export const useMotivBotAI = () => {
  const askMotivBotWithContext = async (taskId, message, taskData = null, conversationHistory = []) => {
    isLoading.value = true
    error.value = null
    const startTime = Date.now()

    try {
      // 1. Preparar petición a OpenAI
      const proxyServer = import.meta.env.VITE_PROXY_SERVER
      if (!proxyServer) {
        throw new Error('VITE_PROXY_SERVER no está configurado')
      }

      // 2. Preparar historial de conversación para el contexto
      let conversationContext = ''
      if (conversationHistory && conversationHistory.length > 0) {
        // Limitar a las últimas 10 conversaciones para no sobrecargar
        const recentHistory = conversationHistory.slice(-10)

        conversationContext = recentHistory.map(conv => {
          const role = conv.role === 'user' ? 'Usuario' : 'MotivBot'
          return `${role}: ${conv.message}`
        }).join('\n')

        console.log('📝 Incluyendo historial de conversación:', recentHistory.length, 'mensajes')
      }

      const requestBody = {
        message: message.trim(),
        context: `Ayuda al usuario con su comentario sobre la tarea. ${conversationContext ? `\n\nHistorial de conversación:\n${conversationContext}` : ''}`,
        taskData: taskData,
        conversationHistory: conversationHistory // Enviar también el historial completo
      }

      console.log('🤖 Enviando consulta a MotivBot...', {
        message: message.substring(0, 50) + '...',
        taskId,
        hasTaskData: !!taskData,
        historyLength: conversationHistory?.length || 0
      })

      const response = await fetch(`${proxyServer}/api/openai`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody)
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.message || `Error HTTP: ${response.status}`)
      }

      const data = await response.json()

      if (!data.success || !data.message) {
        throw new Error('Respuesta inválida del servidor')
      }

      console.log('✅ Respuesta de MotivBot recibida')
      console.log('🎭 Estado emocional recibido:', data.emotionalState) // ✅ Log para verificar

      return {
        message: data.message,
        emotionalState: data.emotionalState, // ✅ ¡AGREGAR ESTA LÍNEA!
        usage: data.usage,
        timestamp: data.timestamp,
        responseTime: Date.now() - startTime
      }

    } catch (err) {
      error.value = err.message
      console.error('❌ Error en conversación con MotivBot:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  return {
    // Estado
    isLoading,
    error,

    // Métodos
    askMotivBotWithContext
  }
}
