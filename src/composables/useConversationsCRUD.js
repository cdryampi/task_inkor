import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabaseClient'

const conversations = ref([])
const loading = ref(false)
const error = ref(null)

export const useConversationsCRUD = () => {

  // **CREATE** - Crear nueva conversación
  const createConversation = async (conversationData) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .from('Conversation')
        .insert([conversationData])
        .select()
        .single()

      if (supabaseError) throw supabaseError

      conversations.value.push(data)
      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error creando conversación:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **READ** - Obtener conversaciones
  const getConversations = async (filters = {}) => {
    loading.value = true
    error.value = null

    try {
      let query = supabase
        .from('Conversation')
        .select(`
          *,
          Task (
            id,
            title,
            description,
            status,
            priority
          )
        `)

      // Aplicar filtros
      if (filters.taskId) {
        query = query.eq('task_id', filters.taskId)
      }

      if (filters.role) {
        query = query.eq('role', filters.role)
      }

      if (filters.limit) {
        query = query.limit(filters.limit)
      }

      // Ordenar por fecha
      query = query.order('created_at', { ascending: filters.ascending || false })

      const { data, error: supabaseError } = await query

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

  // **UPDATE** - Actualizar conversación
  const updateConversation = async (id, updates) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .from('Conversation')
        .update(updates)
        .eq('id', id)
        .select()
        .single()

      if (supabaseError) throw supabaseError

      // Actualizar en la lista local
      const index = conversations.value.findIndex(conv => conv.id === id)
      if (index !== -1) {
        conversations.value[index] = { ...conversations.value[index], ...data }
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

  // **DELETE** - Eliminar conversación
  const deleteConversation = async (id) => {
    loading.value = true
    error.value = null

    try {
      const { error: supabaseError } = await supabase
        .from('Conversation')
        .delete()
        .eq('id', id)

      if (supabaseError) throw supabaseError

      // Remover de la lista local
      conversations.value = conversations.value.filter(conv => conv.id !== id)

      return true

    } catch (err) {
      error.value = err.message
      console.error('❌ Error eliminando conversación:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **RPC** - Obtener historial completo de tarea
  const getTaskConversationHistory = async (taskId) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .rpc('get_task_conversation_history', { p_task_id: taskId })

      if (supabaseError) throw supabaseError

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error obteniendo historial:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **RPC** - Añadir conversación desde GPT Actions
  const addGPTConversation = async (taskId, role, message, options = {}) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .rpc('add_gpt_conversation', {
          p_task_id: taskId,
          p_role: role,
          p_message: message,
          p_source: options.source || 'gpt_actions',
          p_model_used: options.modelUsed || 'gpt-4',
          p_tokens_used: options.tokensUsed || 0
        })

      if (supabaseError) throw supabaseError

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error añadiendo conversación GPT:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **RPC** - Actualizar feedback
  const updateConversationFeedback = async (conversationId, feedback) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .rpc('update_conversation_feedback', {
          p_conversation_id: conversationId,
          p_user_is_grateful: feedback.userIsGrateful || null,
          p_user_is_useful: feedback.userIsUseful || null,
          p_assistant_is_useful: feedback.assistantIsUseful || null,
          p_assistant_is_precise: feedback.assistantIsPrecise || null,
          p_assistant_is_grateful: feedback.assistantIsGrateful || null
        })

      if (supabaseError) throw supabaseError

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error actualizando feedback:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **RPC** - Obtener resumen de conversaciones
  const getConversationSummary = async (taskIds = null, limit = 50) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .rpc('get_conversation_summary', {
          p_task_ids: taskIds,
          p_limit: limit
        })

      if (supabaseError) throw supabaseError

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error obteniendo resumen:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **RPC** - Limpiar conversaciones antiguas
  const cleanupOldConversations = async (daysOld = 30) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .rpc('cleanup_old_conversations', { p_days_old: daysOld })

      if (supabaseError) throw supabaseError

      return data

    } catch (err) {
      error.value = err.message
      console.error('❌ Error limpiando conversaciones:', err)
      throw err
    } finally {
      loading.value = false
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
      totalTokensUsed: assistantMessages.reduce((total, msg) => total + (msg.tokens_used || 0), 0),
      avgResponseTime: assistantMessages.reduce((total, msg) => total + (msg.response_time_ms || 0), 0) / (assistantMessages.length || 1)
    }
  })

  return {
    // Estado
    conversations,
    loading,
    error,
    conversationStats,

    // CRUD Básico
    createConversation,
    getConversations,
    updateConversation,
    deleteConversation,

    // RPC Avanzado
    getTaskConversationHistory,
    addGPTConversation,
    updateConversationFeedback,
    getConversationSummary,
    cleanupOldConversations
  }
}
