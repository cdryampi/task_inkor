import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabaseClient'

const conversations = ref([])
const loading = ref(false)
const error = ref(null)

export const useConversations = () => {

  // Obtener conversaciones por tarea
  const getConversationsByTask = async (taskId) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .from('Conversation')
        .select('*')
        .eq('task_id', taskId)
        .order('created_at', { ascending: true })

      if (supabaseError) throw supabaseError

      conversations.value = data || []
      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error obteniendo conversaciones:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // Crear nueva conversación (mensaje del usuario)
  const createUserMessage = async (taskId, message, feedback = {}) => {
    try {
      const messageData = {
        task_id: taskId,
        role: 'user',
        message: message.trim(),
        user_is_grateful: feedback.isGrateful || false,
        user_is_useful: feedback.isUseful || false
      }

      const { data, error: supabaseError } = await supabase
        .from('Conversation')
        .insert([messageData])
        .select()
        .single()

      if (supabaseError) throw supabaseError

      // Actualizar la lista local
      conversations.value.push(data)
      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error creando mensaje de usuario:', err)
      throw err
    }
  }

  // Crear respuesta del asistente
  const createAssistantMessage = async (taskId, message, metadata = {}) => {
    try {
      const messageData = {
        task_id: taskId,
        role: 'assistant',
        message: message.trim(),
        assistant_is_useful: metadata.isUseful || false,
        assistant_is_precise: metadata.isPrecise || false,
        assistant_is_grateful: metadata.isGrateful || false,
        tokens_used: metadata.tokensUsed || 0,
        model_used: metadata.modelUsed || 'gpt-3.5-turbo',
        response_time_ms: metadata.responseTime || 0
      }

      const { data, error: supabaseError } = await supabase
        .from('Conversation')
        .insert([messageData])
        .select()
        .single()

      if (supabaseError) throw supabaseError

      // Actualizar la lista local
      conversations.value.push(data)
      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error creando mensaje del asistente:', err)
      throw err
    }
  }

  // Actualizar feedback de un mensaje
  const updateMessageFeedback = async (messageId, feedback) => {
    try {
      const { data, error: supabaseError } = await supabase
        .from('Conversation')
        .update(feedback)
        .eq('id', messageId)
        .select()
        .single()

      if (supabaseError) throw supabaseError

      // Actualizar en la lista local
      const index = conversations.value.findIndex(conv => conv.id === messageId)
      if (index !== -1) {
        conversations.value[index] = { ...conversations.value[index], ...data }
      }

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error actualizando feedback:', err)
      throw err
    }
  }

  // Obtener el contexto de la conversación para la IA
  const getConversationContext = (taskData = null) => {
    const recentMessages = conversations.value.slice(-10) // Últimos 10 mensajes

    let context = 'Historial de conversación reciente:\n'

    recentMessages.forEach(msg => {
      const timestamp = new Date(msg.created_at).toLocaleString('es-ES')
      context += `[${timestamp}] ${msg.role === 'user' ? 'Usuario' : 'MotivBot'}: ${msg.message}\n`
    })

    if (taskData) {
      context += `\nInformación de la tarea actual:\n`
      context += `- Título: ${taskData.title}\n`
      if (taskData.description) context += `- Descripción: ${taskData.description}\n`
      if (taskData.priority) context += `- Prioridad: ${taskData.priority}\n`
      if (taskData.due_date) context += `- Fecha límite: ${taskData.due_date}\n`
      context += `- Estado: ${taskData.status}\n`
    }

    return context
  }

  // Eliminar conversaciones de una tarea
  const deleteConversationsByTask = async (taskId) => {
    try {
      const { error: supabaseError } = await supabase
        .from('Conversation')
        .delete()
        .eq('task_id', taskId)

      if (supabaseError) throw supabaseError

      // Limpiar la lista local
      conversations.value = conversations.value.filter(conv => conv.task_id !== taskId)

    } catch (err) {
      error.value = err.message
      console.error('❌ Error eliminando conversaciones:', err)
      throw err
    }
  }

  // Computed para estadísticas
  const conversationStats = computed(() => {
    const userMessages = conversations.value.filter(conv => conv.role === 'user')
    const assistantMessages = conversations.value.filter(conv => conv.role === 'assistant')

    return {
      totalMessages: conversations.value.length,
      userMessages: userMessages.length,
      assistantMessages: assistantMessages.length,
      gratefulMessages: userMessages.filter(msg => msg.user_is_grateful).length,
      usefulMessages: userMessages.filter(msg => msg.user_is_useful).length,
      totalTokensUsed: assistantMessages.reduce((total, msg) => total + (msg.tokens_used || 0), 0)
    }
  })

  return {
    // Estado
    conversations,
    loading,
    error,
    conversationStats,

    // Métodos
    getConversationsByTask,
    createUserMessage,
    createAssistantMessage,
    updateMessageFeedback,
    getConversationContext,
    deleteConversationsByTask
  }
}
