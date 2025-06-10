import { ref, computed } from 'vue'
import { supabase } from '../lib/supabaseClient'

export const useSupabase = () => {
  // Estado reactivo para las tareas
  const tasks = ref([])
  const loading = ref(false)
  const error = ref(null)

  // Nombre de la tabla detectado automáticamente
  const tableName = ref('task') // Usar 'task' basado en los logs

  // Detectar nombre de tabla automáticamente
  const detectTableName = async () => {
    try {
      // Probar primero con 'Task'
      let { error: taskError } = await supabase
        .from('Task')
        .select('id')
        .limit(1)

      if (!taskError) {
        tableName.value = 'Task'
        return 'Task'
      }

      // Si falla, usar 'task'
      let { error: taskLowerError } = await supabase
        .from('task')
        .select('id')
        .limit(1)

      if (!taskLowerError) {
        tableName.value = 'task'
        return 'task'
      }

      throw new Error('No se encontró la tabla de tareas')
    } catch (err) {
      console.error('❌ Error detectando tabla:', err)
      tableName.value = 'task' // Fallback basado en los logs
      return 'task'
    }
  }

  // Obtener todas las tareas
  const getTasks = async () => {
    loading.value = true
    error.value = null

    try {
      console.log('🔍 Obteniendo tareas desde tabla:', tableName.value)

      const { data, error: supabaseError } = await supabase
        .from(tableName.value)
        .select('*')
        .order('created_at', { ascending: false })

      if (supabaseError) {
        console.error('❌ Error de Supabase:', supabaseError)
        throw new Error(`Supabase Error: ${supabaseError.message}`)
      }

      tasks.value = data || []
      console.log('✅ Tareas cargadas:', data?.length || 0, data)

    } catch (err) {
      const errorMessage = `Error al cargar tareas: ${err.message}`
      error.value = errorMessage
      console.error('❌ Error completo:', err)
    } finally {
      loading.value = false
    }
  }

  // Crear nueva tarea
  const createTask = async (taskData) => {
    loading.value = true
    error.value = null

    try {
      console.log('➕ Creando tarea en tabla:', tableName.value, taskData)

      // Validaciones
      if (!taskData || typeof taskData !== 'object') {
        throw new Error('Datos de tarea inválidos')
      }

      if (!taskData.title || !taskData.title.trim()) {
        throw new Error('El título es requerido')
      }

      // Preparar datos de manera segura
      const newTask = {
        title: String(taskData.title).trim(),
        description: taskData.description ? String(taskData.description).trim() : null,
        status: taskData.status || 'pending',
        due_date: taskData.due_date || null,
        due_time: taskData.due_time || null,
        priority: taskData.priority || 'normal'
      }

      // Limpiar campos vacíos
      Object.keys(newTask).forEach(key => {
        if (newTask[key] === '' || newTask[key] === undefined) {
          newTask[key] = null
        }
      })

      console.log('📝 Datos preparados para insertar:', newTask)

      const { data, error: supabaseError } = await supabase
        .from(tableName.value)
        .insert([newTask])
        .select()

      if (supabaseError) {
        console.error('❌ Error creando tarea:', supabaseError)

        if (supabaseError.code === '23505') {
          throw new Error('Ya existe una tarea con estos datos')
        } else if (supabaseError.code === '42703') {
          throw new Error('Error en la estructura de datos')
        } else {
          throw new Error(`Error al crear tarea: ${supabaseError.message}`)
        }
      }

      if (!data || data.length === 0) {
        throw new Error('No se pudo crear la tarea')
      }

      console.log('✅ Tarea creada exitosamente:', data[0])

      // Actualizar lista de tareas
      tasks.value.unshift(data[0])

      return data[0]
    } catch (err) {
      const errorMessage = `Error al crear tarea: ${err.message}`
      error.value = errorMessage
      console.error('❌ Error completo:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // Actualizar tarea - VERSIÓN MEJORADA
  const updateTask = async (id, updates) => {
    loading.value = true
    error.value = null

    try {
      console.log('🔄 Actualizando tarea en tabla:', tableName.value, { id, updates })

      // Validaciones iniciales
      if (!id) {
        throw new Error('ID de tarea es requerido')
      }

      if (!updates || typeof updates !== 'object' || Object.keys(updates).length === 0) {
        throw new Error('No hay datos para actualizar')
      }

      // Campos permitidos para actualizar
      const allowedFields = ['title', 'description', 'status', 'due_date', 'due_time', 'priority']

      // Filtrar solo campos válidos usando método moderno
      const validUpdates = Object.fromEntries(
        Object.entries(updates).filter(([key, value]) => {
          // Verificar que el campo está permitido
          if (!allowedFields.includes(key)) {
            console.warn(`⚠️ Campo '${key}' no está permitido, se omitirá`)
            return false
          }

          // Permitir valores null, undefined se filtra
          return value !== undefined
        })
      )

      // Verificar que hay campos válidos para actualizar
      if (Object.keys(validUpdates).length === 0) {
        throw new Error('No hay campos válidos para actualizar')
      }

      console.log('📝 Datos validados para actualizar:', validUpdates)

      // Ejecutar actualización
      const { data, error: supabaseError } = await supabase
        .from(tableName.value)
        .update(validUpdates)
        .eq('id', id)
        .select()

      if (supabaseError) {
        console.error('❌ Error de Supabase al actualizar:', supabaseError)

        // Manejo específico de errores comunes
        if (supabaseError.code === '23505') {
          throw new Error('Ya existe una tarea con estos datos')
        } else if (supabaseError.code === '42703') {
          throw new Error('Campo no válido en la base de datos')
        } else if (supabaseError.code === 'PGRST116') {
          throw new Error('Tarea no encontrada')
        } else {
          throw new Error(`Error de Supabase: ${supabaseError.message}`)
        }
      }

      if (!data || data.length === 0) {
        throw new Error('No se encontró la tarea para actualizar (posiblemente fue eliminada)')
      }

      console.log('✅ Tarea actualizada:', data[0])

      // Actualizar en el array local
      const index = tasks.value.findIndex(task => task.id == id)
      if (index !== -1) {
        tasks.value[index] = { ...tasks.value[index], ...data[0] }
        console.log('✅ Array local actualizado')
      } else {
        console.warn('⚠️ Tarea no encontrada en el array local, refrescando...')
        // Opcionalmente recargar todas las tareas si no se encuentra localmente
        await getTasks()
      }

      return data[0]
    } catch (err) {
      const errorMessage = `Error al actualizar tarea: ${err.message}`
      error.value = errorMessage
      console.error('❌ Error completo:', err)
      console.error('❌ Stack trace:', err.stack)
      throw err
    } finally {
      loading.value = false
    }
  }

  // Eliminar tarea
  const deleteTask = async (id) => {
    loading.value = true
    error.value = null

    try {
      console.log('🗑️ Eliminando tarea de tabla:', tableName.value, 'ID:', id)

      if (!id) {
        throw new Error('ID de tarea es requerido')
      }

      const { error: supabaseError } = await supabase
        .from(tableName.value)
        .delete()
        .eq('id', id)

      if (supabaseError) {
        console.error('❌ Error eliminando tarea:', supabaseError)
        throw new Error(`Error al eliminar: ${supabaseError.message}`)
      }

      console.log('✅ Tarea eliminada')

      // Remover del array local
      tasks.value = tasks.value.filter(task => task.id != id)

    } catch (err) {
      const errorMessage = `Error al eliminar tarea: ${err.message}`
      error.value = errorMessage
      console.error('❌ Error completo:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // Marcar tarea como completada
  const toggleTaskStatus = async (id, currentStatus) => {
    try {
      console.log('🔄 Cambiando estado de tarea:', { id, currentStatus })

      if (!id) {
        throw new Error('ID de tarea es requerido')
      }

      if (!currentStatus) {
        throw new Error('Estado actual es requerido')
      }

      const newStatus = currentStatus === 'pending' ? 'completed' : 'pending'
      console.log('📝 Nuevo estado:', newStatus)

      return await updateTask(id, { status: newStatus })
    } catch (err) {
      console.error('❌ Error al cambiar estado:', err)
      throw err
    }
  }

  // Test de conexión mejorado
  const testConnection = async () => {
    try {
      console.log('🔍 Probando conexión a tabla:', tableName.value)

      const { data, error, count } = await supabase
        .from(tableName.value)
        .select('*', { count: 'exact' })
        .limit(1)

      if (error) {
        console.error('❌ Error de conexión:', error)
        return { success: false, error: error.message }
      }

      console.log('✅ Conexión exitosa. Datos de prueba:', { data, count })
      return { success: true, count, sample: data }

    } catch (err) {
      console.error('❌ Error de conexión:', err)
      return { success: false, error: err.message }
    }
  }

  // Computed para tareas filtradas
  const pendingTasks = computed(() =>
    tasks.value.filter(task => task.status === 'pending')
  )

  const completedTasks = computed(() =>
    tasks.value.filter(task => task.status === 'completed')
  )

  // Suscripción en tiempo real mejorada
  const subscribeToTasks = () => {
    try {
      const subscription = supabase
        .channel('tasks')
        .on('postgres_changes',
          { event: '*', schema: 'public', table: tableName.value },
          (payload) => {
            console.log('🔄 Cambio recibido:', payload)
            getTasks()
          }
        )
        .subscribe()

      console.log('📡 Suscripción activada para tabla:', tableName.value)
      return subscription
    } catch (err) {
      console.error('❌ Error en suscripción:', err)
      return null
    }
  }

  return {
    // Estado reactivo
    tasks,
    loading,
    error,
    pendingTasks,
    completedTasks,

    // Métodos
    getTasks,
    createTask,
    updateTask,
    deleteTask,
    toggleTaskStatus,
    subscribeToTasks,
    testConnection,
    detectTableName,

    // Cliente directo para casos especiales
    supabase
  }
}
