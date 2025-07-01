import { ref, computed } from 'vue'
import {
  FaceSmileIcon as FaceSmileIconSolid,
  SparklesIcon as SparklesIconSolid,
  CloudIcon as CloudIconSolid,
  EyeIcon as EyeIconSolid,
  HandRaisedIcon as HandRaisedIconSolid,
  BoltIcon as BoltIconSolid,
  BeakerIcon as BeakerIconSolid,
  HeartIcon as HeartIconSolid
} from '@heroicons/vue/24/solid'

export const useCommentCard = (props, emit) => {
  const copied = ref(false)
  const showDeleteConfirm = ref(false)
  const deleting = ref(false)

  const commentTypeClass = computed(() => {
    return props.comment.role === 'assistant'
      ? 'bg-gradient-to-br from-purple-50 to-white border-l-4 border-l-purple-500 group hover:shadow-lg hover:-translate-y-0.5'
      : 'bg-gradient-to-br from-blue-50 to-white border-l-4 border-l-blue-500 group hover:shadow-lg hover:-translate-y-0.5'
  })

  const avatarBgClass = computed(() => {
    return props.comment.role === 'assistant'
      ? 'bg-gradient-to-br from-purple-100 to-purple-200'
      : 'bg-gradient-to-br from-blue-100 to-blue-200'
  })

  const authorClass = computed(() => {
    return props.comment.role === 'assistant'
      ? 'text-purple-800'
      : 'text-blue-800'
  })

  const formatRelativeTime = (dateString) => {
    const now = new Date()
    const commentDate = new Date(dateString)
    const diffInMinutes = Math.floor((now - commentDate) / (1000 * 60))

    if (diffInMinutes < 1) return 'ahora'
    if (diffInMinutes < 60) return `hace ${diffInMinutes}m`

    const diffInHours = Math.floor(diffInMinutes / 60)
    if (diffInHours < 24) return `hace ${diffInHours}h`

    const diffInDays = Math.floor(diffInHours / 24)
    if (diffInDays < 7) return `hace ${diffInDays}d`

    return commentDate.toLocaleDateString('es-ES')
  }

  const copyContent = async () => {
    try {
      await navigator.clipboard.writeText(props.comment.message)
      copied.value = true
      setTimeout(() => {
        copied.value = false
      }, 2000)
    } catch (err) {
      console.error('Error copiando contenido:', err)
    }
  }

  const deleteComment = () => {
    showDeleteConfirm.value = true
  }

  const confirmDelete = async () => {
    deleting.value = true
    try {
      emit('delete', props.comment.id)
      showDeleteConfirm.value = false
    } catch (err) {
      console.error('Error eliminando comentario:', err)
    } finally {
      deleting.value = false
    }
  }

  const askAI = () => {
    console.log('💬 CommentCard - Solicitando consejo de AI para:', props.comment.message)
    emit('ask-ai', props.comment.message)
  }

  const toggleReaction = (type) => {
    const feedbackData = {}

    switch (type) {
      case 'useful':
        if (props.comment.role === 'user') {
          feedbackData.user_is_useful = !props.comment.user_is_useful
        } else {
          feedbackData.assistant_is_useful = !props.comment.assistant_is_useful
        }
        break
      case 'precise':
        feedbackData.assistant_is_precise = !props.comment.assistant_is_precise
        break
      case 'grateful':
        if (props.comment.role === 'user') {
          feedbackData.user_is_grateful = !props.comment.user_is_grateful
        } else {
          feedbackData.assistant_is_grateful = !props.comment.assistant_is_grateful
        }
        break
    }

    console.log('👍 CommentCard - Actualizando feedback:', {
      commentId: props.comment.id,
      type,
      feedbackData
    })

    emit('update-feedback', props.comment.id, feedbackData)
  }

  const getEmotionalStateIcon = (state) => {
    const icons = {
      happy: FaceSmileIconSolid,
      excited: SparklesIconSolid,
      calm: CloudIconSolid,
      focused: EyeIconSolid,
      supportive: HandRaisedIconSolid,
      encouraging: HeartIconSolid,
      thoughtful: BeakerIconSolid,
      energetic: BoltIconSolid
    }
    return icons[state] || FaceSmileIconSolid
  }

  const getEmotionalStateColor = (state) => {
    const colors = {
      happy: 'text-yellow-500',
      excited: 'text-orange-500',
      calm: 'text-blue-500',
      focused: 'text-purple-500',
      supportive: 'text-green-500',
      encouraging: 'text-pink-500',
      thoughtful: 'text-indigo-500',
      energetic: 'text-red-500'
    }
    return colors[state] || 'text-gray-500'
  }

  const formatModelName = (modelName) => {
    const modelDisplayNames = {
      'gpt-4': 'GPT-4',
      'gpt-4-turbo': 'GPT-4 Turbo',
      'gpt-4o': 'GPT-4o',
      'gpt-4o-mini': 'GPT-4o Mini',
      'gpt-3.5-turbo': 'GPT-3.5',
      'claude-3-sonnet': 'Claude 3',
      'claude-3-haiku': 'Claude 3 Haiku',
      'gemini-pro': 'Gemini Pro'
    }
    return modelDisplayNames[modelName] || modelName
  }

  return {
    copied,
    showDeleteConfirm,
    deleting,
    commentTypeClass,
    avatarBgClass,
    authorClass,
    formatRelativeTime,
    copyContent,
    deleteComment,
    confirmDelete,
    askAI,
    toggleReaction,
    getEmotionalStateIcon,
    getEmotionalStateColor,
    formatModelName
  }
}
