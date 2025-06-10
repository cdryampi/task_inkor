<template>
  <div class="container mx-auto p-4 max-w-6xl">
    <!-- Loading state -->
    <div v-if="loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
      <p class="mt-4 text-primary-600 text-lg">Cargando tarea...</p>
    </div>

    <!-- Error state -->
    <div v-else-if="error" class="bg-red-100 border border-red-400 text-red-700 px-6 py-4 rounded-lg">
      <div class="flex items-center space-x-2">
        <ExclamationCircleIcon class="w-5 h-5" />
        <span>{{ error }}</span>
      </div>
    </div>

    <!-- Task Detail Content -->
    <div v-else-if="task" class="space-y-6">
      <!-- Header con navegación minimalista -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="flex items-center justify-between mb-6">
          <button
            @click="$router.back()"
            class="flex items-center space-x-2 text-gray-500 hover:text-gray-700 px-2 py-1 rounded-md transition-colors duration-200">
            <ArrowLeftIcon class="w-4 h-4" />
            <span class="text-sm">Volver</span>
          </button>

          <div class="flex items-center space-x-2">
            <button
              @click="openEditModal"
              class="flex items-center space-x-1 text-gray-500 hover:text-blue-600 px-2 py-1 rounded-md transition-colors duration-200">
              <PencilIcon class="w-4 h-4" />
              <span class="text-sm">Editar</span>
            </button>
            <button
              @click="deleteTaskHandler"
              class="flex items-center space-x-1 text-gray-500 hover:text-red-600 px-2 py-1 rounded-md transition-colors duration-200">
              <TrashIcon class="w-4 h-4" />
              <span class="text-sm">Eliminar</span>
            </button>
          </div>
        </div>

        <!-- Task Header -->
        <div class="border-b border-gray-200 pb-6">
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-start space-x-4 flex-1">
              <!-- Task Icon based on priority/status -->
              <div class="flex-shrink-0 mt-1">
                <div class="w-12 h-12 rounded-xl flex items-center justify-center" :class="getTaskIconBg()">
                  <component :is="getTaskIcon()" class="w-6 h-6" :class="getTaskIconColor()" />
                </div>
              </div>

              <div class="flex-1">
                <h1 class="text-3xl font-bold text-gray-900 mb-2">{{ task.title }}</h1>
                <div class="flex items-center space-x-3">
                  <!-- Status Badge -->
                  <span class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium" :class="getStatusClass(task.status)">
                    <component :is="getStatusIcon(task.status)" class="w-3 h-3 mr-1" />
                    {{ getStatusLabel(task.status) }}
                  </span>
                  <!-- Priority Badge -->
                  <span class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium" :class="getPriorityClass(task.priority)">
                    <component :is="getPriorityIcon(task.priority)" class="w-3 h-3 mr-1" />
                    {{ getPriorityLabel(task.priority) }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Quick Actions minimalistas -->
          <div class="flex items-center justify-between">
            <select
              v-model="task.status"
              @change="updateTaskStatus"
              class="text-sm border-0 border-b border-gray-300 focus:border-primary-500 focus:ring-0 bg-transparent px-0 py-1">
              <option value="pending">Pendiente</option>
              <option value="in-progress">En Progreso</option>
              <option value="completed">Completada</option>
            </select>
            <div class="text-xs text-gray-400">
              Creada {{ formatRelativeDate(task.created_at) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Description -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h2 class="text-lg font-semibold text-gray-800 mb-4 flex items-center space-x-2">
              <DocumentTextIcon class="w-5 h-5 text-gray-400" />
              <span>Descripción</span>
            </h2>
            <div class="prose prose-sm max-w-none">
              <p v-if="task.description" class="text-gray-700 leading-relaxed">
                {{ task.description }}
              </p>
              <p v-else class="text-gray-400 italic">
                No hay descripción disponible para esta tarea.
              </p>
            </div>
          </div>

          <!-- Comments Section -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h2 class="text-lg font-semibold text-gray-800 mb-4 flex items-center justify-between">
              <div class="flex items-center space-x-2">
                <ChatBubbleLeftRightIcon class="w-5 h-5 text-gray-400" />
                <span>Comentarios</span>
                <span class="bg-gray-100 text-gray-500 px-2 py-1 rounded-full text-xs">
                  {{ comments.length }}
                </span>
              </div>
              <button
                @click="showAddComment = !showAddComment"
                class="flex items-center space-x-1 text-gray-500 hover:text-primary-600 px-2 py-1 rounded-md transition-colors text-sm">
                <PlusIcon class="w-4 h-4" />
                <span>Agregar</span>
              </button>
            </h2>

            <!-- Add Comment Form -->
            <div v-show="showAddComment" class="mb-6 p-4 bg-gray-50 rounded-lg">
              <form @submit.prevent="addComment" class="space-y-3">
                <textarea
                  v-model="newComment"
                  placeholder="Escribe un comentario..."
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-1 focus:ring-primary-500 focus:border-primary-500 resize-none text-sm"
                  required></textarea>
                <div class="flex justify-end space-x-2">
                  <button
                    type="button"
                    @click="showAddComment = false"
                    class="px-3 py-1 text-gray-500 hover:text-gray-700 text-sm transition-colors">
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    :disabled="!newComment.trim() || addingComment"
                    class="px-3 py-1 bg-primary-500 text-white rounded-md hover:bg-primary-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm">
                    <span v-if="addingComment">Agregando...</span>
                    <span v-else>Comentar</span>
                  </button>
                </div>
              </form>
            </div>

            <!-- Comments List -->
            <div class="space-y-4">
              <CommentCard
                v-for="comment in comments"
                :key="comment.id"
                :comment="comment"
                @delete="deleteComment"
                @ask-ai="askAI" />

              <!-- Empty State -->
              <div v-if="comments.length === 0" class="text-center py-8">
                <ChatBubbleLeftRightIcon class="w-12 h-12 text-gray-300 mx-auto mb-3" />
                <p class="text-gray-500 text-sm">No hay comentarios aún</p>
                <p class="text-gray-400 text-xs">¡Sé el primero en comentar!</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Task Details -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center space-x-2">
              <InformationCircleIcon class="w-5 h-5 text-gray-400" />
              <span>Detalles</span>
            </h3>

            <div class="space-y-4">
              <!-- Due Date -->
              <div v-if="task.due_date" class="flex items-center justify-between">
                <span class="text-sm text-gray-500 flex items-center space-x-2">
                  <CalendarDaysIcon class="w-4 h-4" />
                  <span>Fecha límite:</span>
                </span>
                <div class="text-right">
                  <div class="text-sm font-medium text-gray-900">
                    {{ formatDate(task.due_date) }}
                  </div>
                  <div v-if="getDaysUntilDue(task.due_date)"
                       class="text-xs"
                       :class="getDaysUntilDue(task.due_date) < 0 ? 'text-red-500' : 'text-gray-400'">
                    {{ getDaysUntilDueText(task.due_date) }}
                  </div>
                </div>
              </div>

              <!-- Due Time -->
              <div v-if="task.due_time" class="flex items-center justify-between">
                <span class="text-sm text-gray-500 flex items-center space-x-2">
                  <ClockIcon class="w-4 h-4" />
                  <span>Hora:</span>
                </span>
                <span class="text-sm font-medium text-gray-900">
                  {{ formatTime(task.due_time) }}
                </span>
              </div>

              <!-- Created Date -->
              <div class="flex items-center justify-between">
                <span class="text-sm text-gray-500 flex items-center space-x-2">
                  <PlusCircleIcon class="w-4 h-4" />
                  <span>Creada:</span>
                </span>
                <span class="text-sm font-medium text-gray-900">
                  {{ formatDate(task.created_at) }}
                </span>
              </div>

              <!-- Updated Date -->
              <div v-if="task.updated_at !== task.created_at" class="flex items-center justify-between">
                <span class="text-sm text-gray-500 flex items-center space-x-2">
                  <PencilIcon class="w-4 h-4" />
                  <span>Actualizada:</span>
                </span>
                <span class="text-sm font-medium text-gray-900">
                  {{ formatDate(task.updated_at) }}
                </span>
              </div>
            </div>
          </div>

          <!-- Progress Card -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center space-x-2">
              <ChartBarIcon class="w-5 h-5 text-gray-400" />
              <span>Progreso</span>
            </h3>

            <div class="space-y-4">
              <!-- Progress Bar -->
              <div>
                <div class="flex justify-between text-sm text-gray-500 mb-2">
                  <span>Completado</span>
                  <span>{{ getProgressPercentage() }}%</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div
                    class="h-2 rounded-full transition-all duration-300"
                    :class="getProgressBarClass()"
                    :style="{ width: `${getProgressPercentage()}%` }">
                  </div>
                </div>
              </div>

              <!-- Stats -->
              <div class="grid grid-cols-2 gap-4 pt-2">
                <div class="text-center">
                  <div class="text-2xl font-bold text-gray-600">
                    {{ comments.filter(c => c.type === 'user').length }}
                  </div>
                  <div class="text-xs text-gray-400">Comentarios</div>
                </div>
                <div class="text-center">
                  <div class="text-2xl font-bold text-gray-600">
                    {{ comments.filter(c => c.type === 'ai').length }}
                  </div>
                  <div class="text-xs text-gray-400">Respuestas AI</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Task not found -->
    <div v-else class="text-center py-12">
      <ExclamationCircleIcon class="w-16 h-16 text-gray-300 mx-auto mb-4" />
      <h2 class="text-xl font-semibold text-gray-800 mb-2">Tarea no encontrada</h2>
      <p class="text-gray-500 mb-4">La tarea que buscas no existe o ha sido eliminada.</p>
      <button
        @click="$router.push('/mis-tareas')"
        class="px-4 py-2 text-primary-600 hover:text-primary-700 hover:bg-primary-50 rounded-md transition-colors text-sm">
        Ver todas las tareas
      </button>
    </div>

    <!-- Edit Task Modal -->
    <NewTaskModal
      :isOpen="isEditModalOpen"
      :loading="updatingTask"
      :editTask="formatTaskForModal(task)"
      @close="closeEditModal"
      @update="handleUpdateTask" />
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  ArrowLeftIcon,
  PencilIcon,
  TrashIcon,
  CalendarDaysIcon,
  ClockIcon,
  DocumentTextIcon,
  InformationCircleIcon,
  ChartBarIcon,
  PlusCircleIcon,
  ExclamationCircleIcon,
  ChatBubbleLeftRightIcon,
  PlusIcon,
  CheckCircleIcon,
  PlayIcon,
  ClipboardDocumentListIcon,
  MinusIcon,
  BoltIcon,
  LightBulbIcon
} from '@heroicons/vue/24/outline'
import {
  ExclamationTriangleIcon as ExclamationTriangleIconSolid,
  FireIcon as FireIconSolid,
  CheckCircleIcon as CheckCircleIconSolid,
  PlayIcon as PlayIconSolid
} from '@heroicons/vue/24/solid'
import { useSupabase } from '@/hooks/supabase'
import NewTaskModal from '@/components/modals/NewTaskModal.vue'
import CommentCard from '@/components/comments/CommentCard.vue'

const route = useRoute()
const router = useRouter()
const { getTaskById, updateTask, deleteTask } = useSupabase()

// State
const task = ref(null)
const loading = ref(true)
const error = ref(null)
const isEditModalOpen = ref(false)
const updatingTask = ref(false)

// Comments state
const comments = ref([])
const newComment = ref('')
const showAddComment = ref(false)
const addingComment = ref(false)

// Methods
const loadTask = async () => {
  try {
    loading.value = true
    const taskData = await getTaskById(route.params.id)
    task.value = taskData

    // Load comments (mock data for now)
    loadComments()
  } catch (err) {
    console.error('Error cargando tarea:', err)
    error.value = 'Error al cargar la tarea'
  } finally {
    loading.value = false
  }
}

const loadComments = () => {
  // Mock comments - replace with real API call
  comments.value = [
    {
      id: 1,
      type: 'user',
      content: 'Comenzando a trabajar en esta tarea. Parece compleja pero interesante.',
      created_at: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
      author: 'Usuario'
    },
    {
      id: 2,
      type: 'ai',
      content: 'Te sugiero dividir esta tarea en subtareas más pequeñas. Esto te ayudará a mantener el progreso y la motivación. ¿Te gustaría que te ayude a estructurarla?',
      created_at: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
      author: 'Asistente AI'
    }
  ]
}

const addComment = async () => {
  if (!newComment.value.trim()) return

  addingComment.value = true

  try {
    // Add user comment
    const userComment = {
      id: Date.now(),
      type: 'user',
      content: newComment.value.trim(),
      created_at: new Date().toISOString(),
      author: 'Usuario'
    }

    comments.value.push(userComment)
    newComment.value = ''
    showAddComment.value = false

    // TODO: Save to database

  } catch (err) {
    console.error('Error agregando comentario:', err)
  } finally {
    addingComment.value = false
  }
}

const askAI = async (commentContent) => {
  try {
    // Mock AI response - replace with real AI API call
    const aiResponse = {
      id: Date.now() + 1,
      type: 'ai',
      content: `Basándome en tu comentario "${commentContent}", te sugiero lo siguiente: Esta es una excelente observación. Para avanzar de manera efectiva, podrías considerar establecer pequeños hitos intermedios que te permitan evaluar el progreso regularmente.`,
      created_at: new Date().toISOString(),
      author: 'Asistente AI'
    }

    comments.value.push(aiResponse)
  } catch (err) {
    console.error('Error obteniendo respuesta de AI:', err)
  }
}

const deleteComment = (commentId) => {
  if (confirm('¿Estás seguro de eliminar este comentario?')) {
    comments.value = comments.value.filter(c => c.id !== commentId)
  }
}

const openEditModal = () => {
  isEditModalOpen.value = true
}

const closeEditModal = () => {
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
    dueDate: task.due_date,
    dueTime: task.due_time
  }
}

const handleUpdateTask = async (taskData) => {
  updatingTask.value = true
  try {
    await updateTask(taskData.id, taskData)
    // Reload task data
    await loadTask()
    closeEditModal()
    console.log('✅ Tarea actualizada exitosamente')
  } catch (err) {
    console.error('❌ Error actualizando tarea:', err)
  } finally {
    updatingTask.value = false
  }
}

const updateTaskStatus = async () => {
  try {
    await updateTask(task.value.id, { status: task.value.status })
    console.log('✅ Estado actualizado exitosamente')
  } catch (err) {
    console.error('❌ Error actualizando estado:', err)
  }
}

const deleteTaskHandler = async () => {
  if (confirm('¿Estás seguro de que quieres eliminar esta tarea? Esta acción no se puede deshacer.')) {
    try {
      await deleteTask(task.value.id)
      router.push('/mis-tareas')
      console.log('✅ Tarea eliminada exitosamente')
    } catch (err) {
      console.error('❌ Error eliminando tarea:', err)
    }
  }
}

// Task Icon functions
const getTaskIcon = () => {
  if (task.value.status === 'completed') return CheckCircleIconSolid
  if (task.value.priority === 'high') return FireIconSolid
  if (task.value.priority === 'medium') return ExclamationTriangleIconSolid
  if (task.value.status === 'in-progress') return PlayIconSolid
  return ClipboardDocumentListIcon
}

const getTaskIconBg = () => {
  if (task.value.status === 'completed') return 'bg-green-100'
  if (task.value.priority === 'high') return 'bg-red-100'
  if (task.value.priority === 'medium') return 'bg-yellow-100'
  if (task.value.status === 'in-progress') return 'bg-blue-100'
  return 'bg-gray-100'
}

const getTaskIconColor = () => {
  if (task.value.status === 'completed') return 'text-green-600'
  if (task.value.priority === 'high') return 'text-red-600'
  if (task.value.priority === 'medium') return 'text-yellow-600'
  if (task.value.status === 'in-progress') return 'text-blue-600'
  return 'text-gray-600'
}

// Helper functions
const getStatusClass = (status) => {
  switch (status) {
    case 'pending': return 'bg-gray-100 text-gray-700'
    case 'in-progress': return 'bg-blue-100 text-blue-700'
    case 'completed': return 'bg-green-100 text-green-700'
    default: return 'bg-gray-100 text-gray-700'
  }
}

const getStatusIcon = (status) => {
  switch (status) {
    case 'pending': return ClipboardDocumentListIcon
    case 'in-progress': return PlayIcon
    case 'completed': return CheckCircleIcon
    default: return MinusIcon
  }
}

const getStatusLabel = (status) => {
  switch (status) {
    case 'pending': return 'Pendiente'
    case 'in-progress': return 'En Progreso'
    case 'completed': return 'Completada'
    default: return 'Desconocido'
  }
}

const getPriorityClass = (priority) => {
  switch (priority) {
    case 'high': return 'bg-red-100 text-red-700'
    case 'medium': return 'bg-yellow-100 text-yellow-700'
    case 'normal': return 'bg-gray-100 text-gray-700'
    default: return 'bg-gray-100 text-gray-700'
  }
}

const getPriorityIcon = (priority) => {
  switch (priority) {
    case 'high': return FireIconSolid
    case 'medium': return ExclamationTriangleIconSolid
    case 'normal': return MinusIcon
    default: return MinusIcon
  }
}

const getPriorityLabel = (priority) => {
  switch (priority) {
    case 'high': return 'Alta'
    case 'medium': return 'Media'
    case 'normal': return 'Normal'
    default: return 'Normal'
  }
}

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const formatTime = (time) => {
  return new Date(`2000-01-01T${time}`).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatRelativeDate = (date) => {
  const now = new Date()
  const taskDate = new Date(date)
  const diffInDays = Math.floor((now - taskDate) / (1000 * 60 * 60 * 24))

  if (diffInDays === 0) return 'hoy'
  if (diffInDays === 1) return 'ayer'
  if (diffInDays < 7) return `hace ${diffInDays} días`
  if (diffInDays < 30) return `hace ${Math.floor(diffInDays / 7)} semanas`
  return `hace ${Math.floor(diffInDays / 30)} meses`
}

const getDaysUntilDue = (dueDate) => {
  const now = new Date()
  const due = new Date(dueDate)
  return Math.ceil((due - now) / (1000 * 60 * 60 * 24))
}

const getDaysUntilDueText = (dueDate) => {
  const days = getDaysUntilDue(dueDate)
  if (days < 0) return `Vencida hace ${Math.abs(days)} días`
  if (days === 0) return 'Vence hoy'
  if (days === 1) return 'Vence mañana'
  return `Vence en ${days} días`
}

const getProgressPercentage = () => {
  if (!task.value) return 0
  switch (task.value.status) {
    case 'pending': return 0
    case 'in-progress': return 50
    case 'completed': return 100
    default: return 0
  }
}

const getProgressBarClass = () => {
  const percentage = getProgressPercentage()
  if (percentage === 0) return 'bg-gray-300'
  if (percentage < 100) return 'bg-blue-500'
  return 'bg-green-500'
}

// Load task on mount
onMounted(() => {
  loadTask()
})
</script>

<style scoped>
.prose p {
  margin-bottom: 1rem;
  line-height: 1.6;
}

/* Estilo minimalista para el select */
select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");
  background-position: right 0.5rem center;
  background-repeat: no-repeat;
  background-size: 1.5em 1.5em;
  padding-right: 2.5rem;
}
</style>
