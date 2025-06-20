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
        .from('conversation')
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
        user_is_useful: feedback.isUseful || false,
        emotional_state: feedback.emotionalState || null // ✅ Corregido: emotional_state en lugar de emocional_state
      }

      const { data, error: supabaseError } = await supabase
        .from('conversation')
        .insert([messageData])
        .select()
        .maybeSingle() // ✅ Cambiado a maybeSingle

      if (supabaseError) throw supabaseError

      // Actualizar la lista local
      if (data) {
        conversations.value.push(data)
      }

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error creando mensaje de usuario:', err)
      throw err
    }
  }

  // Crear respuesta del asistente con estado emocional
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
        response_time_ms: metadata.responseTime || 0,
        emotional_state: metadata.emotionalState || 'supportive', // ✅ Corregido y con valor por defecto
        suggestions: metadata.suggestions || null // ✅ Añadido soporte para sugerencias
      }

      console.log('💾 Guardando mensaje del asistente:', {
        task_id: taskId,
        emotional_state: messageData.emotional_state,
        message_preview: message.substring(0, 50) + '...'
      })

      const { data, error: supabaseError } = await supabase
        .from('conversation')
        .insert([messageData])
        .select()
        .maybeSingle() // ✅ Cambiado a maybeSingle

      if (supabaseError) throw supabaseError

      // Actualizar la lista local
      if (data) {
        conversations.value.push(data)
        console.log('✅ Mensaje del asistente guardado con estado:', data.emotional_state)
      }

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error creando mensaje del asistente:', err)
      throw err
    }
  }

  // Actualizar feedback de un mensaje (incluyendo estado emocional)
  const updateMessageFeedback = async (messageId, feedback) => {
    try {
      // Preparar datos de actualización
      const updateData = {}

      // Feedback básico
      if (feedback.isGrateful !== undefined) updateData.user_is_grateful = feedback.isGrateful
      if (feedback.isUseful !== undefined) updateData.user_is_useful = feedback.isUseful
      if (feedback.isPrecise !== undefined) updateData.assistant_is_precise = feedback.isPrecise
      if (feedback.assistantIsUseful !== undefined) updateData.assistant_is_useful = feedback.assistantIsUseful
      if (feedback.assistantIsGrateful !== undefined) updateData.assistant_is_grateful = feedback.assistantIsGrateful

      // Estado emocional (puede ser actualizado por el usuario o sistema)
      if (feedback.emotionalState !== undefined) updateData.emotional_state = feedback.emotionalState

      const { data, error: supabaseError } = await supabase
        .from('conversation')
        .update(updateData)
        .eq('id', messageId)
        .select()
        .maybeSingle() // ✅ Cambiado a maybeSingle

      if (supabaseError) throw supabaseError

      // Actualizar en la lista local
      if (data) {
        const index = conversations.value.findIndex(conv => conv.id === messageId)
        if (index !== -1) {
          conversations.value[index] = { ...conversations.value[index], ...data }
        }
      }

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error actualizando feedback:', err)
      throw err
    }
  }

  // Obtener el contexto de la conversación para la IA (incluyendo estados emocionales)
  const getConversationContext = (taskData = null) => {
    const recentMessages = conversations.value.slice(-10) // Últimos 10 mensajes

    let context = 'Historial de conversación reciente:\n'

    recentMessages.forEach(msg => {
      const timestamp = new Date(msg.created_at).toLocaleString('es-ES')
      const emotionalInfo = msg.emotional_state ? ` [Estado: ${msg.emotional_state}]` : ''
      context += `[${timestamp}] ${msg.role === 'user' ? 'Usuario' : 'MotivBot'}${emotionalInfo}: ${msg.message}\n`
    })

    if (taskData) {
      context += `\nInformación de la tarea actual:\n`
      context += `- Título: ${taskData.title}\n`
      if (taskData.description) context += `- Descripción: ${taskData.description}\n`
      if (taskData.priority) context += `- Prioridad: ${taskData.priority}\n`
      if (taskData.due_date) context += `- Fecha límite: ${taskData.due_date}\n`
      if (taskData.tags && Array.isArray(taskData.tags)) context += `- Tags: ${taskData.tags.join(', ')}\n`
      context += `- Estado: ${taskData.status}\n`
    }

    return context
  }

  // Obtener estado emocional más reciente del asistente
  const getLastEmotionalState = () => {
    const assistantMessages = conversations.value
      .filter(conv => conv.role === 'assistant' && conv.emotional_state)
      .reverse() // Más reciente primero

    return assistantMessages.length > 0 ? assistantMessages[0].emotional_state : 'supportive'
  }

  // Obtener historial de estados emocionales
  const getEmotionalStateHistory = () => {
    return conversations.value
      .filter(conv => conv.role === 'assistant' && conv.emotional_state)
      .map(conv => ({
        id: conv.id,
        emotional_state: conv.emotional_state,
        message_preview: conv.message.substring(0, 100),
        created_at: conv.created_at
      }))
  }

  // Eliminar conversaciones de una tarea
  const deleteConversationsByTask = async (taskId) => {
    try {
      const { error: supabaseError } = await supabase
        .from('conversation')
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

  // Computed para estadísticas (incluyendo estados emocionales)
  const conversationStats = computed(() => {
    const userMessages = conversations.value.filter(conv => conv.role === 'user')
    const assistantMessages = conversations.value.filter(conv => conv.role === 'assistant')

    // Análisis de estados emocionales
    const emotionalStates = assistantMessages
      .filter(msg => msg.emotional_state)
      .reduce((acc, msg) => {
        acc[msg.emotional_state] = (acc[msg.emotional_state] || 0) + 1
        return acc
      }, {})

    const mostCommonState = Object.keys(emotionalStates).reduce(
      (a, b) => emotionalStates[a] > emotionalStates[b] ? a : b,
      'supportive'
    )

    return {
      totalMessages: conversations.value.length,
      userMessages: userMessages.length,
      assistantMessages: assistantMessages.length,
      gratefulMessages: userMessages.filter(msg => msg.user_is_grateful).length,
      usefulMessages: userMessages.filter(msg => msg.user_is_useful).length,
      totalTokensUsed: assistantMessages.reduce((total, msg) => total + (msg.tokens_used || 0), 0),
      // ✅ Nuevas estadísticas emocionales
      emotionalStates,
      mostCommonEmotionalState: mostCommonState,
      lastEmotionalState: getLastEmotionalState(),
      messagesWithEmotionalState: assistantMessages.filter(msg => msg.emotional_state).length
    }
  })

  return {
    // Estado
    conversations,
    loading,
    error,
    conversationStats,

    // Métodos básicos
    getConversationsByTask,
    createUserMessage,
    createAssistantMessage,
    updateMessageFeedback,
    getConversationContext,
    deleteConversationsByTask,

    // ✅ Métodos para estados emocionales
    getLastEmotionalState,
    getEmotionalStateHistory
  }
}
