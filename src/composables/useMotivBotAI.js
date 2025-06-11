import { ref } from 'vue'
import { useConversations } from './useConversations'

const isLoading = ref(false)
const error = ref(null)

export const useMotivBotAI = () => {
  const { createUserMessage, createAssistantMessage, getConversationContext } = useConversations()

  const askMotivBotWithContext = async (taskId, message, taskData = null) => {
    isLoading.value = true
    error.value = null
    const startTime = Date.now()

    try {
      // 1. Guardar mensaje del usuario
      await createUserMessage(taskId, message)

      // 2. Obtener contexto de la conversación
      const conversationContext = getConversationContext(taskData)

      // 3. Preparar petición a OpenAI
      const proxyServer = import.meta.env.VITE_PROXY_SERVER
      if (!proxyServer) {
        throw new Error('VITE_PROXY_SERVER no está configurado')
      }

      const requestBody = {
        message: message.trim(),
        context: conversationContext,
        taskData: taskData
      }

      console.log('🤖 Enviando consulta a MotivBot con contexto...', {
        message: message.substring(0, 50) + '...',
        hasContext: !!conversationContext,
        taskId
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

      // 4. Guardar respuesta del asistente
      const responseTime = Date.now() - startTime
      await createAssistantMessage(taskId, data.message, {
        tokensUsed: data.usage?.total_tokens || 0,
        modelUsed: 'gpt-3.5-turbo',
        responseTime: responseTime
      })

      console.log('✅ Conversación guardada correctamente')

      return {
        message: data.message,
        usage: data.usage,
        timestamp: data.timestamp,
        responseTime: responseTime
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
