import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'

const todayTasks = ref([])
const isLoading = ref(false)
const error = ref(null)

export const useTodayTasks = () => {

  // **GET** - Obtener tareas activas y actualizar su fecha
  const getTodayTasks = async () => {
    isLoading.value = true
    error.value = null

    try {
      console.log('🔄 Iniciando actualización de fechas...')

      // ✅ Calcular fechas para hoy
      const today = new Date()
      const todayDate = today.toISOString().split('T')[0] // YYYY-MM-DD
      const currentTime = today.toTimeString().slice(0, 8) // HH:MM:SS

      // 1. Actualizar fechas de tareas activas
      const { data: updateData, error: updateError, count } = await supabase
        .from('task')
        .update({
          updated_at: new Date().toISOString(),
          due_date: todayDate,    // ✅ Actualizar fecha de vencimiento a hoy
          due_time: currentTime   // ✅ Actualizar hora de vencimiento a ahora
        })
        .in('status', ['pending', 'in-progress', 'on-hold'])
        .select()

      if (updateError) {
        console.error('❌ Error actualizando fechas:', updateError)
        throw new Error(`Error actualizando fechas: ${updateError.message}`)
      }

      console.log(`✅ Fechas actualizadas en ${updateData?.length || 0} tareas`)
      console.log(`📅 Nueva fecha de vencimiento: ${todayDate} ${currentTime}`)

      // 2. Obtener las tareas actualizadas
      const { data, error: fetchError } = await supabase
        .from('task')
        .select('id, title, description, status, priority, tags, due_date, due_time, created_at, updated_at') // ✅ Incluir due_date y due_time
        .in('status', ['pending', 'in-progress', 'on-hold'])
        .order('priority', { ascending: false })
        .order('updated_at', { ascending: false })

      if (fetchError) {
        console.error('❌ Error obteniendo tareas:', fetchError)
        throw new Error(`Error obteniendo tareas: ${fetchError.message}`)
      }

      todayTasks.value = data || []
      console.log(`✅ ${todayTasks.value.length} tareas activas encontradas`)

      // ✅ Log detallado para debug incluyendo fechas
      if (todayTasks.value.length > 0) {
        console.log('📋 Muestra de tareas actualizadas:',
          todayTasks.value.slice(0, 3).map(task => ({
            id: task.id,
            title: task.title,
            status: task.status,
            priority: task.priority,
            due_date: task.due_date,
            due_time: task.due_time,
            updated_at: task.updated_at
          }))
        )
      }

      return todayTasks.value

    } catch (err) {
      console.error('❌ Error completo:', err)
      error.value = err.message
      throw err
    } finally {
      isLoading.value = false
    }
  }

  return {
    todayTasks,
    isLoading,
    error,
    getTodayTasks
  }
}
