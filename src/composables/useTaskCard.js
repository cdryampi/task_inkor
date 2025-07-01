import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import {
  ExclamationTriangleIcon as ExclamationTriangleIconSolid,
  FireIcon as FireIconSolid
} from '@heroicons/vue/24/solid'
import {
  MinusIcon
} from '@heroicons/vue/24/outline'

export const useTaskCard = (props, emit) => {
  const router = useRouter()

  const isEditModalOpen = ref(false)
  const updatingTask = ref(false)
  const localStatus = ref(props.task.status)

  const taskStatusClass = computed(() => `status-${localStatus.value}`)

  watch(
    () => props.task.status,
    (newStatus) => {
      console.log('🔄 TaskCard - Status de prop cambió:', newStatus)
      localStatus.value = newStatus
    },
    { immediate: true }
  )

  const openEditModal = () => {
    console.log('✏️ TaskCard - Abriendo modal de edición:', props.task.id)
    isEditModalOpen.value = true
  }

  const closeEditModal = () => {
    console.log('❌ TaskCard - Cerrando modal de edición')
    isEditModalOpen.value = false
  }

  const formatTaskForModal = (task) => {
    if (!task) return null
    return {
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority || 'normal',
      dueDate: task.dueDate,
      dueTime: task.dueTime
    }
  }

  const handleUpdateTask = async (taskData) => {
    updatingTask.value = true
    try {
      console.log('🔄 TaskCard - Actualizando tarea:', taskData)
      emit('update-task', taskData)
      closeEditModal()
      console.log('✅ TaskCard - Tarea actualizada exitosamente')
    } catch (err) {
      console.error('❌ TaskCard - Error actualizando tarea:', err)
    } finally {
      updatingTask.value = false
    }
  }

  const viewTask = () => {
    console.log('👁️ TaskCard - Navegando a detalle de tarea:', props.task.id)
    router.push(`/task/${props.task.id}`)
  }

  const deleteTask = () => {
    console.log('🗑️ TaskCard - Emitiendo delete-task:', props.task.id)
    emit('delete-task', props.task.id)
  }

  const updateStatus = () => {
    console.log('🔄 TaskCard - Emitiendo update-status:', props.task.id, localStatus.value)
    console.log('📊 TaskCard - Status anterior:', props.task.status, '-> Nuevo:', localStatus.value)
    emit('update-status', props.task.id, localStatus.value)
  }

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString('es-ES')
  }

  const formatTime = (timeStr) => {
    if (!timeStr) return ''
    return new Date(`2000-01-01T${timeStr}`).toLocaleTimeString('es-ES', {
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const getPriorityClass = (priority) => {
    switch (priority) {
      case 'high':
        return 'bg-gradient-to-r from-red-100 to-red-200 text-red-800 border border-red-300 shadow-sm'
      case 'medium':
        return 'bg-gradient-to-r from-yellow-100 to-yellow-200 text-yellow-800 border border-yellow-300 shadow-sm'
      default:
        return 'bg-gradient-to-r from-gray-100 to-gray-200 text-gray-700 border border-gray-300'
    }
  }

  const getPriorityIcon = (priority) => {
    switch (priority) {
      case 'high':
        return FireIconSolid
      case 'medium':
        return ExclamationTriangleIconSolid
      default:
        return MinusIcon
    }
  }

  const getPriorityLabel = (priority) => {
    switch (priority) {
      case 'high':
        return 'Urgente'
      case 'medium':
        return 'Media'
      default:
        return 'Normal'
    }
  }

  return {
    isEditModalOpen,
    updatingTask,
    localStatus,
    taskStatusClass,
    openEditModal,
    closeEditModal,
    formatTaskForModal,
    handleUpdateTask,
    viewTask,
    deleteTask,
    updateStatus,
    formatDate,
    formatTime,
    getPriorityClass,
    getPriorityIcon,
    getPriorityLabel
  }
}
