import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabaseClient'

const conversations = ref([])
const loading = ref(false)
const error = ref(null)
const conversationStats = ref({
  userMessages: 0,
  assistantMessages: 0,
  totalTokensUsed: 0,
  usefulMessages: 0
})

export const useConversationsCRUD = () => {

  // **CREATE** - Crear nueva conversación
  const createConversation = async (conversationData) => {
    loading.value = true
    error.value = null

    try {
      console.log('💬 useConversationsCRUD - Creando conversación:', conversationData)

      // ✅ VALIDAR QUE task_id ESTÁ PRESENTE
      if (!conversationData.task_id) {
        throw new Error('task_id es requerido')
      }

      const { data, error: insertError } = await supabase
        .from('conversation')
        .insert([conversationData])
        .select()

      if (insertError) {
        console.error('❌ useConversationsCRUD - Error creando conversación:', insertError)
        throw insertError
      }

      console.log('✅ useConversationsCRUD - Conversación creada:', data[0])
      return data[0]

    } catch (err) {
      error.value = err.message
      console.error('❌ Error creando conversación:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // **READ** - Obtener conversaciones
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
        .eq('task_id', taskId) // ✅ FILTRO ESPECÍFICO
        .order('created_at', { ascending: true })

      if (fetchError) {
        console.error('❌ useConversationsCRUD - Error Supabase:', fetchError)
        throw fetchError
      }

      conversations.value = data || []

      console.log('✅ useConversationsCRUD - Conversaciones obtenidas:', conversations.value.length)
      console.log('📊 useConversationsCRUD - Conversaciones:', conversations.value.map(c => ({ id: c.id, task_id: c.task_id, role: c.role })))

      // ✅ CALCULAR STATS
      calculateStats()

    } catch (err) {
      console.error('❌ useConversationsCRUD - Error:', err)
      error.value = err.message
      conversations.value = []
    } finally {
      loading.value = false
    }
  }

  // ✅ MÉTODO PARA CALCULAR ESTADÍSTICAS
  const calculateStats = () => {
    const stats = {
      userMessages: 0,
      assistantMessages: 0,
      totalTokensUsed: 0,
      usefulMessages: 0
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
    })

    conversationStats.value = stats
    console.log('📊 useConversationsCRUD - Stats calculadas:', stats)
  }

  // **UPDATE** - Actualizar conversación
  const updateConversation = async (id, updates) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: supabaseError } = await supabase
        .from('conversation')
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
  const deleteConversation = async (conversationId) => {
    loading.value = true
    error.value = null

    try {
      const { data, error: rpcError } = await supabase.rpc('motivbot_delete_conversation', {
        p_conversation_id: conversationId
      })

      if (rpcError) throw rpcError

      if (!data.success) {
        throw new Error(data.message)
      }

      // Remover de la lista local
      conversations.value = conversations.value.filter(conv => conv.id !== conversationId)

      console.log('✅ Conversación eliminada exitosamente')
      return data
    } catch (err) {
      console.error('❌ Error eliminando conversación:', err)
      error.value = err.message
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
  const conversationStatsComputed = computed(() => {
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
    conversationStats: conversationStatsComputed,

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
