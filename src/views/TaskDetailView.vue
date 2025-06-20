<template>
  <div class="container mx-auto p-4 max-w-7xl">
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
                  <!-- Tags -->
                  <div v-if="task.tags && task.tags.length > 0" class="flex items-center space-x-1">
                    <span
                      v-for="tag in task.tags.slice(0, 3)"
                      :key="tag"
                      class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-purple-100 text-purple-700"
                    >
                      #{{ tag }}
                    </span>
                    <span
                      v-if="task.tags.length > 3"
                      class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-gray-100 text-gray-500"
                    >
                      +{{ task.tags.length - 3 }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Quick Actions minimalistas -->
          <div class="flex items-center justify-between">
            <select
              v-model="task.status"
              @change="callUpdateTaskStatus"
              class="text-sm border-0 border-b border-gray-300 focus:border-primary-500 focus:ring-0 bg-transparent px-0 py-1">
              <option value="pending">Pendiente</option>
              <option value="in-progress">En Progreso</option>
              <option value="on-hold">En Pausa</option>
              <option value="completed">Completada</option>
              <option value="cancelled">Cancelada</option>
            </select>
            <div class="text-xs text-gray-400">
              Creada {{ formatRelativeDate(task.created_at) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content Grid - ACTUALIZADO para 3 columnas -->
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
        <!-- Main Content - 2 columnas -->
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
                <span>Conversaciones</span>
                <span class="bg-gray-100 text-gray-500 px-2 py-1 rounded-full text-xs">
                  {{ conversations.length }}
                </span>
                <!-- ✅ Mostrar último estado emocional -->
                <div v-if="lastEmotionalState" class="flex items-center space-x-1">
                  <span class="text-xs text-gray-400">MotivBot:</span>
                  <span class="text-sm">{{ getEmotionalStateEmoji(lastEmotionalState) }}</span>
                </div>
              </div>
              <button
                @click="showAddComment = !showAddComment"
                class="flex items-center space-x-1 text-gray-500 hover:text-primary-600 px-2 py-1 rounded-md transition-colors text-sm">
                <PlusIcon class="w-4 h-4" />
                <span>Agregar</span>
              </button>
            </h2>

            <!-- Loading conversations -->
            <div v-if="conversationsLoading" class="text-center py-4">
              <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-primary-500"></div>
              <p class="mt-2 text-sm text-gray-500">Cargando conversaciones...</p>
            </div>

            <!-- Add Comment Form -->
            <div v-show="showAddComment" class="mb-6 p-4 bg-gray-50 rounded-lg">
              <form @submit.prevent="addComment" class="space-y-3">
                <textarea
                  v-model="newComment"
                  placeholder="Escribe un comentario o pregunta algo a MotivBot..."
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-1 focus:ring-primary-500 focus:border-primary-500 resize-none text-sm"
                  required></textarea>
                <div class="flex justify-between items-center">
                  <div class="flex items-center space-x-2">
                    <input
                      id="askAiDirectly"
                      v-model="askAiDirectly"
                      type="checkbox"
                      class="w-4 h-4 text-primary-600 bg-gray-100 border-gray-300 rounded focus:ring-primary-500"
                    />
                    <label for="askAiDirectly" class="text-xs text-gray-600">
                      🤖 Pedir respuesta automática de MotivBot
                    </label>
                  </div>
                  <div class="flex space-x-2">
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
                      <span v-if="addingComment">{{ askAiDirectly ? 'Enviando y pidiendo consejo...' : 'Agregando...' }}</span>
                      <span v-else>{{ askAiDirectly ? 'Enviar y pedir consejo' : 'Comentar' }}</span>
                    </button>
                  </div>
                </div>
              </form>
            </div>

            <!-- Comments List -->
            <div class="space-y-4">
              <CommentCard
                v-for="comment in conversations"
                :key="comment.id"
                :comment="comment"
                :aiLoading="aiLoading"
                @delete="deleteComment"
                @ask-ai="askAI"
                @update-feedback="updateConversationFeedback" />

              <!-- Empty State -->
              <div v-if="conversations.length === 0 && !conversationsLoading" class="text-center py-8">
                <ChatBubbleLeftRightIcon class="w-12 h-12 text-gray-300 mx-auto mb-3" />
                <p class="text-gray-500 text-sm">No hay conversaciones aún</p>
                <p class="text-gray-400 text-xs">¡Sé el primero en comentar o preguntarle a MotivBot!</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Task Details Sidebar - 1 columna -->
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

              <!-- Tags section -->
              <div v-if="task.tags && task.tags.length > 0" class="pt-4 border-t border-gray-100">
                <span class="text-sm text-gray-500 mb-2 block">Tags:</span>
                <div class="flex flex-wrap gap-1">
                  <span
                    v-for="tag in task.tags"
                    :key="tag"
                    class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-purple-100 text-purple-700"
                  >
                    #{{ tag }}
                  </span>
                </div>
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
                    {{ conversationStats.userMessages }}
                  </div>
                  <div class="text-xs text-gray-400">Comentarios</div>
                </div>
                <div class="text-center">
                  <div class="text-2xl font-bold text-gray-600">
                    {{ conversationStats.assistantMessages }}
                  </div>
                  <div class="text-xs text-gray-400">Respuestas AI</div>
                </div>
              </div>

              <!-- ✅ Estadísticas emocionales -->
              <div v-if="conversationStats.emotionalStateDistribution && Object.keys(conversationStats.emotionalStateDistribution).length > 0" class="pt-2 border-t border-gray-100">
                <div class="text-xs text-gray-500 mb-2">Estados emocionales de MotivBot:</div>
                <div class="grid grid-cols-4 gap-1">
                  <div
                    v-for="(count, state) in conversationStats.emotionalStateDistribution"
                    :key="state"
                    class="text-center"
                    :title="`${state}: ${count} veces`"
                  >
                    <div class="text-lg">{{ getEmotionalStateEmoji(state) }}</div>
                    <div class="text-xs text-gray-400">{{ count }}</div>
                  </div>
                </div>
              </div>

              <!-- Conversation Stats -->
              <div class="pt-2 border-t border-gray-100">
                <div class="grid grid-cols-2 gap-2 text-xs text-gray-500">
                  <div>Tokens: {{ conversationStats.totalTokensUsed }}</div>
                  <div>Útiles: {{ conversationStats.usefulMessages }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- ✅ MotivBot Assistant Sidebar - 1 columna -->
        <div class="space-y-6">
          <ChibiMotivBotComponentTask
            :task="task"
            :conversation-history="conversations"
            :last-emotional-state="lastEmotionalState"
            @conversation-added="loadConversations"
          />
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

    <!-- Modal de edición con estado local -->
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
  PauseIcon,
  BoltIcon,
  LightBulbIcon,
  XCircleIcon
} from '@heroicons/vue/24/outline'
import {
  ExclamationTriangleIcon as ExclamationTriangleIconSolid,
  FireIcon as FireIconSolid,
  CheckCircleIcon as CheckCircleIconSolid,
  PlayIcon as PlayIconSolid

} from '@heroicons/vue/24/solid'
import { useSupabase } from '@/hooks/supabase'
import { useConversationsCRUD } from '@/composables/useConversationsCRUD'
import { useMotivBotAI } from '@/composables/useMotivBotAI'
import NewTaskModal from '@/components/modals/NewTaskModal.vue'
import CommentCard from '@/components/comments/CommentCard.vue'
import ChibiMotivBotComponentTask from '@/components/tasks/ChibiMotivBotComponentTask.vue'

const route = useRoute()
const router = useRouter()
const { getTaskById, updateTask, deleteTask } = useSupabase()

// Conversations composable
const {
  conversations,
  loading: conversationsLoading,
  error: conversationsError,
  conversationStats,
  getConversations,
  createConversation,
  createAssistantMessage,
  createUserMessage,
  updateConversation,
  deleteConversation,
  getLastEmotionalState
} = useConversationsCRUD()

// ✅ MOTIVBOT AI composable
const { askMotivBotWithContext, isLoading: aiLoading } = useMotivBotAI()

// Estado completamente local
const task = ref(null)
const loading = ref(true)
const error = ref(null)
const isEditModalOpen = ref(false)
const updatingTask = ref(false)

// Comments state
const newComment = ref('')
const showAddComment = ref(false)
const addingComment = ref(false)
const askAiDirectly = ref(false) // ✅ Nueva opción para pedir respuesta automática

// ✅ Computed para último estado emocional
const lastEmotionalState = computed(() => {
  return getLastEmotionalState()
})

// ✅ Método para eliminar tarea
const deleteTaskHandler = async () => {
  if (!confirm('¿Estás seguro de que quieres eliminar esta tarea? Esta acción no se puede deshacer.')) {
    return
  }

  try {
    await deleteTask(task.value.id)
    router.push('/mis-tareas')
  } catch (err) {
    console.error('❌ Error eliminando tarea:', err)
    error.value = 'Error al eliminar la tarea'
  }
}

// Métodos locales para el modal
const openEditModal = () => {
  console.log('🔧 TaskDetailView - Abriendo modal de edición local')
  isEditModalOpen.value = true
}

const closeEditModal = () => {
  console.log('🔧 TaskDetailView - Cerrando modal de edición local')
  isEditModalOpen.value = false
}

const formatTaskForModal = (taskData) => {
  if (!taskData) return null
  return {
    id: taskData.id,
    title: taskData.title,
    description: taskData.description,
    status: taskData.status,
    priority: taskData.priority || 'normal',
    dueDate: taskData.due_date,
    dueTime: taskData.due_time,
    task_id: taskData.id
  }
}

const handleUpdateTask = async (taskData) => {
  updatingTask.value = true
  try {
    console.log('🔄 TaskDetailView - Actualizando tarea:', taskData)
    await updateTask(taskData.id, taskData)
    await loadTask() // Reload task data
    closeEditModal()
    console.log('✅ TaskDetailView - Tarea actualizada exitosamente')
  } catch (err) {
    console.error('❌ TaskDetailView - Error actualizando tarea:', err)
  } finally {
    updatingTask.value = false
  }
}

// ✅ Métodos principales
const loadTask = async () => {
  try {
    console.log('🔄 TaskDetailView - Cargando tarea:', route.params.id)
    const taskData = await getTaskById(parseInt(route.params.id))
    task.value = taskData
  } catch (err) {
    console.error('❌ TaskDetailView - Error cargando tarea:', err)
    error.value = 'Error cargando la tarea'
  } finally {
    loading.value = false
  }
}

const loadConversations = async () => {
  try {
    console.log('🔄 TaskDetailView - Cargando conversaciones para tarea:', route.params.id)
    const taskId = parseInt(route.params.id)

    if (!taskId) {
      console.error('❌ TaskDetailView - Task ID no válido:', route.params.id)
      return
    }

    await getConversations(taskId)
    console.log('✅ TaskDetailView - Conversaciones cargadas:', conversations.value.length)

  } catch (err) {
    console.error('❌ TaskDetailView - Error cargando conversaciones:', err)
  }
}

// ✅ MEJORADO: addComment con opción de IA automática
const addComment = async () => {
  if (!newComment.value.trim()) return

  addingComment.value = true

  try {
    const taskId = parseInt(route.params.id)

    console.log('💬 TaskDetailView - Agregando comentario para tarea:', taskId)

    // Crear mensaje del usuario
    await createUserMessage(taskId, newComment.value.trim())

    // Si el usuario quiere respuesta automática de IA
    if (askAiDirectly.value) {
      console.log('🤖 TaskDetailView - Solicitando respuesta automática de MotivBot...')

      // Recargar conversaciones para incluir el nuevo comentario en el contexto
      await loadConversations()

      // Obtener respuesta de MotivBot
      const aiResponse = await askMotivBotWithContext(
        taskId,
        newComment.value.trim(),
        {
          title: task.value?.title,
          description: task.value?.description,
          status: task.value?.status,
          priority: task.value?.priority,
          due_date: task.value?.due_date,
          tags: task.value?.tags
        },
        conversations.value
      )

      // Guardar respuesta del asistente
      await createAssistantMessage(taskId, aiResponse.message, {
        emotionalState: aiResponse.emotionalState,
        tokensUsed: aiResponse.usage?.total_tokens || 0,
        responseTime: aiResponse.responseTime,
        modelUsed: 'gpt-3.5-turbo',
        isUseful: false,
        isPrecise: false,
        isGrateful: false
      })
    }

    newComment.value = ''
    showAddComment.value = false
    askAiDirectly.value = false

    // Recargar conversaciones
    await loadConversations()

    console.log('✅ TaskDetailView - Comentario agregado exitosamente')

  } catch (err) {
    console.error('❌ TaskDetailView - Error agregando comentario:', err)
    error.value = 'Error al agregar comentario'
  } finally {
    addingComment.value = false
  }
}

// ✅ MEJORADO: askAI con historial completo
const askAI = async (commentContent) => {
  try {
    console.log('🤖 TaskDetailView - Pidiendo consejo a MotivBot...', commentContent)

    const taskId = parseInt(route.params.id)

    // Crear datos de contexto de la tarea
    const taskContextData = {
      title: task.value?.title,
      description: task.value?.description,
      status: task.value?.status,
      priority: task.value?.priority,
      due_date: task.value?.due_date,
      tags: task.value?.tags
    }

    // Preparar historial de conversaciones (ordenado cronológicamente)
    const sortedHistory = [...conversations.value].sort((a, b) =>
      new Date(a.created_at) - new Date(b.created_at)
    )

    console.log('📋 Incluyendo historial:', {
      totalConversations: sortedHistory.length,
      userComments: sortedHistory.filter(c => c.role === 'user').length,
      aiComments: sortedHistory.filter(c => c.role === 'assistant').length
    })

    // Obtener respuesta de MotivBot con historial
    const aiResponse = await askMotivBotWithContext(
      taskId,
      `Dame un consejo sobre este comentario: "${commentContent}"`,
      taskContextData,
      sortedHistory
    )

    console.log('🤖 Respuesta de MotivBot:', aiResponse.message)

    // Guardar la respuesta como conversación de asistente
    await createAssistantMessage(taskId, aiResponse.message, {
      emotionalState: aiResponse.emotionalState,
      tokensUsed: aiResponse.usage?.total_tokens || 0,
      responseTime: aiResponse.responseTime,
      modelUsed: 'gpt-3.5-turbo',
      isUseful: false,
      isPrecise: false,
      isGrateful: false
    })

    // Recargar conversaciones
    await loadConversations()

    console.log('✅ TaskDetailView - Consejo de AI agregado exitosamente')

  } catch (err) {
    console.error('❌ TaskDetailView - Error obteniendo consejo de AI:', err)
    error.value = 'Error al obtener consejo de la AI'
  }
}

const deleteComment = async (commentId) => {
  try {
    await deleteConversation(commentId)
    await loadConversations()
    console.log('✅ Comentario eliminado exitosamente')
  } catch (err) {
    console.error('❌ Error eliminando comentario:', err)
    error.value = 'Error al eliminar comentario'
  }
}

// ✅ CORREGIDO: updateConversationFeedback
const updateConversationFeedback = async (conversationId, feedbackData) => {
  try {
    console.log('👍 TaskDetailView - Actualizando feedback:', {
      conversationId,
      feedbackData
    })

    await updateConversation(conversationId, feedbackData)
    await loadConversations()

    console.log('✅ Feedback actualizado exitosamente')
  } catch (err) {
    console.error('❌ Error actualizando feedback:', err)
    error.value = 'Error al actualizar feedback'
  }
}

// ✅ Función para obtener emoji del estado emocional
const getEmotionalStateEmoji = (state) => {
  const emojis = {
    happy: '😊',
    excited: '🎉',
    calm: '😌',
    focused: '🎯',
    supportive: '🤗',
    encouraging: '💪',
    thoughtful: '🤔',
    energetic: '⚡'
  }
  return emojis[state] || '🤖'
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
    case 'on-hold': return 'bg-yellow-100 text-yellow-700'
    case 'completed': return 'bg-green-100 text-green-700'
    case 'cancelled': return 'bg-red-100 text-red-700'
    default: return 'bg-gray-100 text-gray-700'
  }
}

const getStatusIcon = (status) => {
  switch (status) {
    case 'pending': return ClipboardDocumentListIcon
    case 'in-progress': return PlayIcon
    case 'on-hold': return PauseIcon
    case 'completed': return CheckCircleIcon
    case 'cancelled': return XCircleIcon
    default: return MinusIcon
  }
}

const getStatusLabel = (status) => {
  switch (status) {
    case 'pending': return 'Pendiente'
    case 'in-progress': return 'En Progreso'
    case 'on-hold': return 'En Pausa'
    case 'completed': return 'Completada'
    case 'cancelled': return 'Cancelada'
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
    case 'on-hold': return 25
    case 'completed': return 100
    case 'cancelled': return 0
    default: return 0
  }
}

const callUpdateTaskStatus = async () => {
  if (!task.value) return
  try {
    console.log('🔄 TaskDetailView - Actualizando estado de tarea:', task.value.status)
    await updateTask(task.value.id, { status: task.value.status })
    await loadTask()
    console.log('✅ TaskDetailView - Estado de tarea actualizado exitosamente')
  } catch (err) {
    console.error('❌ TaskDetailView - Error actualizando estado de tarea:', err)
    error.value = 'Error al actualizar el estado de la tarea'
    await loadTask()
  }
}

const getProgressBarClass = () => {
  const percentage = getProgressPercentage()
  if (percentage === 0) return 'bg-gray-300'
  if (percentage < 100) return 'bg-blue-500'
  return 'bg-green-500'
}

// Cargar datos al montar
onMounted(async () => {
  await Promise.all([
    loadTask(),
    loadConversations()
  ])
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
