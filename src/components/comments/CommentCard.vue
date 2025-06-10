<template>
  <div class="comment-card" :class="commentTypeClass">
    <div class="comment-header">
      <div class="comment-avatar">
        <component
          :is="getAvatarIcon()"
          class="w-6 h-6"
          :class="getAvatarIconClass()" />
      </div>

      <div class="comment-meta">
        <div class="comment-author">
          <span class="font-medium" :class="getAuthorClass()">
            {{ comment.author }}
          </span>
          <span v-if="comment.type === 'ai'" class="ai-badge">
            <SparklesIcon class="w-3 h-3" />
            AI
          </span>
        </div>
        <div class="comment-time">
          {{ formatRelativeTime(comment.created_at) }}
        </div>
      </div>

      <div class="comment-actions">
        <button
          v-if="comment.type === 'user'"
          @click="askAI"
          class="action-btn ai-btn"
          title="Pedir consejo a la AI">
          <SparklesIcon class="w-4 h-4" />
        </button>
        <button
          @click="copyContent"
          class="action-btn copy-btn"
          :title="copied ? 'Copiado!' : 'Copiar contenido'">
          <component :is="copied ? 'CheckIcon' : 'ClipboardIcon'" class="w-4 h-4" />
        </button>
        <button
          v-if="comment.type === 'user'"
          @click="deleteComment"
          class="action-btn delete-btn"
          title="Eliminar comentario">
          <TrashIcon class="w-4 h-4" />
        </button>
      </div>
    </div>

    <div class="comment-content">
      <p class="comment-text">{{ comment.content }}</p>

      <!-- AI suggestions (if AI comment) -->
      <div v-if="comment.type === 'ai' && comment.suggestions" class="ai-suggestions">
        <h4 class="suggestions-title">
          <LightBulbIcon class="w-4 h-4" />
          Sugerencias:
        </h4>
        <ul class="suggestions-list">
          <li v-for="(suggestion, index) in comment.suggestions" :key="index">
            {{ suggestion }}
          </li>
        </ul>
      </div>
    </div>

    <!-- Reaction bar -->
    <div class="comment-reactions">
      <button
        @click="toggleReaction('helpful')"
        class="reaction-btn"
        :class="{ 'active': hasReaction('helpful') }">
        <HandThumbUpIcon class="w-4 h-4" />
        <span>{{ getReactionCount('helpful') || 'Útil' }}</span>
      </button>
      <button
        v-if="comment.type === 'ai'"
        @click="toggleReaction('accurate')"
        class="reaction-btn"
        :class="{ 'active': hasReaction('accurate') }">
        <CheckBadgeIcon class="w-4 h-4" />
        <span>{{ getReactionCount('accurate') || 'Preciso' }}</span>
      </button>
      <button
        @click="toggleReaction('thanks')"
        class="reaction-btn"
        :class="{ 'active': hasReaction('thanks') }">
        <HeartIcon class="w-4 h-4" />
        <span>{{ getReactionCount('thanks') || 'Gracias' }}</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import {
  UserIcon,
  SparklesIcon,
  TrashIcon,
  ClipboardIcon,
  CheckIcon,
  LightBulbIcon,
  HandThumbUpIcon,
  HeartIcon,
  CheckBadgeIcon
} from '@heroicons/vue/24/outline'
import {
  SparklesIcon as SparklesIconSolid,
  UserIcon as UserIconSolid
} from '@heroicons/vue/24/solid'

// Props
const props = defineProps({
  comment: {
    type: Object,
    required: true
  }
})

// Emits
const emit = defineEmits(['delete', 'ask-ai'])

// State
const copied = ref(false)
const reactions = ref(props.comment.reactions || {})

// Computed
const commentTypeClass = computed(() => {
  return props.comment.type === 'ai' ? 'ai-comment' : 'user-comment'
})

// Methods
const getAvatarIcon = () => {
  return props.comment.type === 'ai' ? SparklesIconSolid : UserIconSolid
}

const getAvatarIconClass = () => {
  return props.comment.type === 'ai'
    ? 'text-purple-600'
    : 'text-blue-600'
}

const getAuthorClass = () => {
  return props.comment.type === 'ai'
    ? 'text-purple-800'
    : 'text-blue-800'
}

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
    await navigator.clipboard.writeText(props.comment.content)
    copied.value = true
    setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch (err) {
    console.error('Error copiando contenido:', err)
  }
}

const deleteComment = () => {
  emit('delete', props.comment.id)
}

const askAI = () => {
  emit('ask-ai', props.comment.content)
}

const toggleReaction = (type) => {
  if (!reactions.value[type]) {
    reactions.value[type] = 0
  }

  const hasReacted = hasReaction(type)
  if (hasReacted) {
    reactions.value[type] = Math.max(0, reactions.value[type] - 1)
  } else {
    reactions.value[type] = (reactions.value[type] || 0) + 1
  }

  // TODO: Save reactions to database
}

const hasReaction = (type) => {
  // TODO: Check if current user has reacted
  return false // Placeholder
}

const getReactionCount = (type) => {
  return reactions.value[type] || 0
}
</script>

<style scoped>
.comment-card {
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 16px;
  transition: all 0.2s ease;
  position: relative;
}

.comment-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.user-comment {
  background: linear-gradient(135deg, #f8fafc, #ffffff);
  border-left: 4px solid #3b82f6;
}

.ai-comment {
  background: linear-gradient(135deg, #faf5ff, #ffffff);
  border-left: 4px solid #8b5cf6;
  position: relative;
  overflow: hidden;
}

.ai-comment::before {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 60px;
  height: 60px;
  background: radial-gradient(circle, rgba(139, 92, 246, 0.1) 0%, transparent 70%);
  border-radius: 50%;
  transform: translate(30px, -30px);
}

.comment-header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 12px;
}

.comment-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.user-comment .comment-avatar {
  background: linear-gradient(135deg, #dbeafe, #bfdbfe);
}

.ai-comment .comment-avatar {
  background: linear-gradient(135deg, #f3e8ff, #ddd6fe);
}

.comment-meta {
  flex: 1;
}

.comment-author {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 2px;
}

.ai-badge {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  background: linear-gradient(135deg, #8b5cf6, #7c3aed);
  color: white;
  font-size: 0.75rem;
  font-weight: 500;
  padding: 2px 6px;
  border-radius: 10px;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.comment-time {
  color: #6b7280;
  font-size: 0.875rem;
}

.comment-actions {
  display: flex;
  gap: 4px;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.comment-card:hover .comment-actions {
  opacity: 1;
}

.action-btn {
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  color: #6b7280;
  background: transparent;
}

.action-btn:hover {
  transform: scale(1.05);
}

.ai-btn:hover {
  background: #f3e8ff;
  color: #8b5cf6;
}

.copy-btn:hover {
  background: #f0f9ff;
  color: #0ea5e9;
}

.delete-btn:hover {
  background: #fef2f2;
  color: #ef4444;
}

.comment-content {
  margin-left: 48px;
}

.comment-text {
  color: #374151;
  line-height: 1.6;
  margin-bottom: 12px;
}

.ai-suggestions {
  background: rgba(139, 92, 246, 0.05);
  border: 1px solid rgba(139, 92, 246, 0.2);
  border-radius: 8px;
  padding: 12px;
  margin-top: 12px;
}

.suggestions-title {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #8b5cf6;
  font-weight: 600;
  font-size: 0.875rem;
  margin-bottom: 8px;
}

.suggestions-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.suggestions-list li {
  color: #6b7280;
  font-size: 0.875rem;
  line-height: 1.5;
  padding: 4px 0;
  position: relative;
  padding-left: 16px;
}

.suggestions-list li::before {
  content: '•';
  color: #8b5cf6;
  position: absolute;
  left: 0;
  font-weight: bold;
}

.comment-reactions {
  display: flex;
  gap: 8px;
  margin-left: 48px;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #f3f4f6;
}

.reaction-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  background: white;
  color: #6b7280;
  font-size: 0.75rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.reaction-btn:hover {
  border-color: #d1d5db;
  background: #f9fafb;
}

.reaction-btn.active {
  background: #dbeafe;
  border-color: #3b82f6;
  color: #1d4ed8;
}

/* Responsive */
@media (max-width: 768px) {
  .comment-content,
  .comment-reactions {
    margin-left: 0;
  }

  .comment-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .comment-actions {
    opacity: 1;
  }
}
</style>
