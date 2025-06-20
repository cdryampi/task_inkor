import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabaseClient'

const conversations = ref([])
const loading = ref(false)
const error = ref(null)
const conversationStats = ref({
  userMessages: 0,
  assistantMessages: 0,
  totalTokensUsed: 0,
  usefulMessages: 0,
  emotionalStateDistribution: {} // ✅ Añadido
})

export const useConversationsCRUD = () => {

  // **CREATE** - Crear nueva conversación con estado emocional
  const createConversation = async (conversationData) => {
    loading.value = true
    error.value = null

    try {
      console.log('💬 useConversationsCRUD - Creando conversación:', conversationData)

      // ✅ VALIDAR QUE task_id ESTÁ PRESENTE
      if (!conversationData.task_id) {
        throw new Error('task_id es requerido')
      }

      // ✅ Validar y normalizar estado emocional
      if (conversationData.emotional_state) {
        const validStates = ['happy', 'excited', 'calm', 'focused', 'supportive', 'encouraging', 'thoughtful', 'energetic']
        if (!validStates.includes(conversationData.emotional_state)) {
          console.warn('⚠️ Estado emocional inválido:', conversationData.emotional_state)
          conversationData.emotional_state = 'supportive'
        }
      }

      const { data, error: insertError } = await supabase
        .from('conversation')
        .insert([conversationData])
        .select()

      if (insertError) {
        console.error('❌ useConversationsCRUD - Error creando conversación:', insertError)
        throw insertError
      }

      console.log('✅ useConversationsCRUD - Conversación creada:', {
        id: data[0].id,
        role: data[0].role,
        emotional_state: data[0].emotional_state
      })

      return data[0]

    } catch (err) {
      error.value = err.message
      console.error('❌ Error creando conversación:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **CREATE HELPER** - Crear mensaje del asistente con estado emocional
  const createAssistantMessage = async (taskId, message, metadata = {}) => {
    const conversationData = {
      task_id: taskId,
      role: 'assistant',
      message: message.trim(),
      emotional_state: metadata.emotionalState || 'supportive', // ✅ Estado emocional
      assistant_is_useful: metadata.isUseful || false,
      assistant_is_precise: metadata.isPrecise || false,
      assistant_is_grateful: metadata.isGrateful || false,
      tokens_used: metadata.tokensUsed || 0,
      model_used: metadata.modelUsed || 'gpt-3.5-turbo',
      response_time_ms: metadata.responseTime || 0,
      suggestions: metadata.suggestions || null // ✅ Sugerencias
    }

    console.log('🤖 Creando mensaje del asistente con estado:', metadata.emotionalState)

    return await createConversation(conversationData)
  }

  // **CREATE HELPER** - Crear mensaje del usuario
  const createUserMessage = async (taskId, message, feedback = {}) => {
    const conversationData = {
      task_id: taskId,
      role: 'user',
      message: message.trim(),
      emotional_state: feedback.emotionalState || null, // ✅ Usuario también puede tener estado
      user_is_grateful: feedback.isGrateful || false,
      user_is_useful: feedback.isUseful || false
    }

    return await createConversation(conversationData)
  }

  // **READ** - Obtener conversaciones con estados emocionales
  const getConversations = async (taskId) => {
    loading.value = true
    error.value = null

    try {
      console.log('🔄 useConversationsCRUD - Obteniendo conversaciones para tarea:', taskId)

      if (!taskId) {
        throw new Error('Task ID es requerido')
      }

      // ✅ FILTRAR ESPECÍFICAMENTE POR task_id
      const { data, error: fetchError } = await supabase
        .from('conversation')
        .select('*')
        .eq('task_id', taskId)
        .order('created_at', { ascending: true })

      if (fetchError) {
        console.error('❌ useConversationsCRUD - Error Supabase:', fetchError)
        throw fetchError
      }

      conversations.value = data || []

      console.log('✅ useConversationsCRUD - Conversaciones obtenidas:', {
        total: conversations.value.length,
        withEmotionalState: conversations.value.filter(c => c.emotional_state).length,
        emotionalStates: conversations.value
          .filter(c => c.emotional_state)
          .map(c => c.emotional_state)
      })

      // ✅ CALCULAR STATS INCLUYENDO ESTADOS EMOCIONALES
      calculateStats()

    } catch (err) {
      console.error('❌ useConversationsCRUD - Error:', err)
      error.value = err.message
      conversations.value = []
    } finally {
      loading.value = false
    }
  }

  // ✅ MÉTODO PARA CALCULAR ESTADÍSTICAS INCLUYENDO ESTADOS EMOCIONALES
  const calculateStats = () => {
    const stats = {
      userMessages: 0,
      assistantMessages: 0,
      totalTokensUsed: 0,
      usefulMessages: 0,
      emotionalStateDistribution: {} // ✅ Distribución de estados emocionales
    }

    conversations.value.forEach(conv => {
      if (conv.role === 'user') {
        stats.userMessages++
      } else if (conv.role === 'assistant') {
        stats.assistantMessages++
        stats.totalTokensUsed += conv.tokens_used || 0
      }

      if (conv.user_is_useful) {
        stats.usefulMessages++
      }

      // ✅ Contar distribución de estados emocionales
      if (conv.emotional_state) {
        stats.emotionalStateDistribution[conv.emotional_state] =
          (stats.emotionalStateDistribution[conv.emotional_state] || 0) + 1
      }
    })

    conversationStats.value = stats
    console.log('📊 useConversationsCRUD - Stats calculadas:', {
      ...stats,
      emotionalStates: Object.keys(stats.emotionalStateDistribution)
    })
  }

  // **UPDATE** - Actualizar conversación (incluyendo estado emocional)
  const updateConversation = async (id, updates) => {
    loading.value = true
    error.value = null

    try {
      // ✅ Validar estado emocional si se está actualizando
      if (updates.emotional_state) {
        const validStates = ['happy', 'excited', 'calm', 'focused', 'supportive', 'encouraging', 'thoughtful', 'energetic']
        if (!validStates.includes(updates.emotional_state)) {
          console.warn('⚠️ Estado emocional inválido en actualización:', updates.emotional_state)
          updates.emotional_state = 'supportive'
        }
      }

      const { data, error: supabaseError } = await supabase
        .from('conversation')
        .update(updates)
        .eq('id', id)
        .select()
        .maybeSingle() // ✅ Cambiado a maybeSingle

      if (supabaseError) throw supabaseError

      // Actualizar en la lista local
      if (data) {
        const index = conversations.value.findIndex(conv => conv.id === id)
        if (index !== -1) {
          conversations.value[index] = { ...conversations.value[index], ...data }
          calculateStats() // ✅ Recalcular stats
        }
      }

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error actualizando conversación:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **UPDATE HELPER** - Actualizar solo el estado emocional
  const updateEmotionalState = async (conversationId, newEmotionalState) => {
    return await updateConversation(conversationId, {
      emotional_state: newEmotionalState
    })
  }

  // **DELETE** - Eliminar conversación
  const deleteConversation = async (conversationId) => {
    loading.value = true
    error.value = null

    try {
      const { error: deleteError } = await supabase
        .from('conversation')
        .delete()
        .eq('id', conversationId)

      if (deleteError) throw deleteError

      // Remover de la lista local
      conversations.value = conversations.value.filter(conv => conv.id !== conversationId)
      calculateStats() // ✅ Recalcular stats

      console.log('✅ Conversación eliminada exitosamente')
      return { success: true }
    } catch (err) {
      console.error('❌ Error eliminando conversación:', err)
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  // **HELPER** - Obtener último estado emocional
  const getLastEmotionalState = () => {
    const assistantMessages = conversations.value
      .filter(conv => conv.role === 'assistant' && conv.emotional_state)
      .reverse()

    return assistantMessages.length > 0 ? assistantMessages[0].emotional_state : 'supportive'
  }

  // **HELPER** - Obtener contexto con estados emocionales
  const getConversationContext = (taskData = null) => {
    const recentMessages = conversations.value.slice(-10)

    let context = 'Historial de conversación reciente:\n'

    recentMessages.forEach(msg => {
      const timestamp = new Date(msg.created_at).toLocaleString('es-ES')
      const emotionalInfo = msg.emotional_state ? ` [${msg.emotional_state}]` : ''
      context += `[${timestamp}] ${msg.role === 'user' ? 'Usuario' : 'MotivBot'}${emotionalInfo}: ${msg.message}\n`
    })

    if (taskData) {
      context += `\nInformación de la tarea:\n`
      context += `- Título: ${taskData.title}\n`
      if (taskData.description) context += `- Descripción: ${taskData.description}\n`
      if (taskData.priority) context += `- Prioridad: ${taskData.priority}\n`
      if (taskData.due_date) context += `- Fecha límite: ${taskData.due_date}\n`
      if (taskData.tags) context += `- Tags: ${JSON.stringify(taskData.tags)}\n`
      context += `- Estado: ${taskData.status}\n`
    }

    return context
  }

  // Computed para estadísticas avanzadas (incluyendo estados emocionales)
  const conversationStatsComputed = computed(() => {
    const userMessages = conversations.value.filter(conv => conv.role === 'user')
    const assistantMessages = conversations.value.filter(conv => conv.role === 'assistant')

    // ✅ Análisis de estados emocionales
    const emotionalStates = assistantMessages
      .filter(msg => msg.emotional_state)
      .reduce((acc, msg) => {
        acc[msg.emotional_state] = (acc[msg.emotional_state] || 0) + 1
        return acc
      }, {})

    const mostCommonState = Object.keys(emotionalStates).length > 0
      ? Object.keys(emotionalStates).reduce((a, b) => emotionalStates[a] > emotionalStates[b] ? a : b)
      : 'supportive'

    return {
      totalMessages: conversations.value.length,
      userMessages: userMessages.length,
      assistantMessages: assistantMessages.length,
      gratefulMessages: userMessages.filter(msg => msg.user_is_grateful).length,
      usefulMessages: userMessages.filter(msg => msg.user_is_useful).length,
      totalTokensUsed: assistantMessages.reduce((total, msg) => total + (msg.tokens_used || 0), 0),
      avgResponseTime: assistantMessages.reduce((total, msg) => total + (msg.response_time_ms || 0), 0) / (assistantMessages.length || 1),
      // ✅ Estadísticas emocionales
      emotionalStateDistribution: emotionalStates,
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
    conversationStats: conversationStatsComputed,

    // CRUD Básico con soporte emocional
    createConversation,
    createAssistantMessage, // ✅ Helper específico
    createUserMessage, // ✅ Helper específico
    getConversations,
    updateConversation,
    updateEmotionalState, // ✅ Helper específico
    deleteConversation,

    // ✅ Helpers para estados emocionales
    getLastEmotionalState,
    getConversationContext
  }
}
