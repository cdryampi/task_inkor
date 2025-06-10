<template>
  <div class="task-card" :class="taskStatusClass">
    <div class="task-header">
      <h3 class="task-title">{{ task.title }}</h3>
      <div class="task-actions">
        <button @click="viewTask" class="action-btn view-btn" title="Ver detalles">
          <EyeIcon class="w-4 h-4" />
        </button>
        <button @click="editTask" class="action-btn edit-btn" title="Editar tarea">
          <PencilIcon class="w-4 h-4" />
        </button>
        <button @click="deleteTask" class="action-btn delete-btn" title="Eliminar tarea">
          <TrashIcon class="w-4 h-4" />
        </button>
      </div>
    </div>

    <p class="task-description">{{ task.description }}</p>

    <div class="task-meta">
      <span class="task-priority" :class="getPriorityClass(task.priority || 'normal')">
        <component :is="getPriorityIcon(task.priority || 'normal')" class="w-3 h-3" />
        {{ getPriorityLabel(task.priority || 'normal') }}
      </span>
      <div class="task-datetime" v-if="task.dueDate">
        <span class="task-due-date">
          <CalendarDaysIcon class="w-3 h-3" />
          {{ formatDate(task.dueDate) }}
        </span>
        <span v-if="task.dueTime" class="task-due-time">
          <ClockIcon class="w-3 h-3" />
          {{ formatTime(task.dueTime) }}
        </span>
      </div>
    </div>

    <div class="task-footer">
      <div class="task-status">
        <ClipboardDocumentListIcon class="w-4 h-4 text-gray-500" />
        <select v-model="task.status" @change="updateStatus" class="status-select">
          <option value="pending">Pendiente</option>
          <option value="in-progress">En Progreso</option>
          <option value="completed">Completada</option>
        </select>
      </div>
      <div class="task-tags" v-if="task.tags && task.tags.length">
        <span v-for="tag in task.tags" :key="tag" class="tag">
          <TagIcon class="w-3 h-3" />
          {{ tag }}
        </span>
      </div>
    </div>

    <!-- Botón flotante para ver detalles (alternativa más visible) -->
    <button
      @click="viewTask"
      class="view-details-btn"
      title="Ver detalles completos">
      <ArrowTopRightOnSquareIcon class="w-4 h-4" />
      <span class="sr-only">Ver detalles</span>
    </button>
  </div>
</template>

<script>
import { useRouter } from 'vue-router'
import {
  PencilIcon,
  TrashIcon,
  CalendarDaysIcon,
  ClipboardDocumentListIcon,
  TagIcon,
  MinusIcon,
  ClockIcon,
  EyeIcon,
  ArrowTopRightOnSquareIcon
} from '@heroicons/vue/24/outline'
import {
  ExclamationTriangleIcon as ExclamationTriangleIconSolid,
  FireIcon as FireIconSolid
} from '@heroicons/vue/24/solid'

export default {
  name: 'TaskCard',
  components: {
    PencilIcon,
    TrashIcon,
    CalendarDaysIcon,
    ClipboardDocumentListIcon,
    TagIcon,
    MinusIcon,
    ClockIcon,
    EyeIcon,
    ArrowTopRightOnSquareIcon,
    ExclamationTriangleIconSolid,
    FireIconSolid
  },
  props: {
    task: {
      type: Object,
      required: true
    }
  },
  setup() {
    const router = useRouter()
    return { router }
  },
  computed: {
    taskStatusClass() {
      return `status-${this.task.status}`;
    }
  },
  methods: {
    viewTask() {
      this.router.push(`/task/${this.task.id}`)
    },
    editTask() {
      this.$emit('edit-task', this.task);
    },
    deleteTask() {
      this.$emit('delete-task', this.task.id);
    },
    updateStatus() {
      this.$emit('update-status', this.task.id, this.task.status);
    },
    formatDate(date) {
      return new Date(date).toLocaleDateString('es-ES');
    },
    formatTime(timeStr) {
      if (!timeStr) return ''
      return new Date(`2000-01-01T${timeStr}`).toLocaleTimeString('es-ES', {
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    getPriorityClass(priority) {
      switch (priority) {
        case 'high':
          return 'bg-gradient-to-r from-red-100 to-red-200 text-red-800 border border-red-300 shadow-sm'
        case 'medium':
          return 'bg-gradient-to-r from-yellow-100 to-yellow-200 text-yellow-800 border border-yellow-300 shadow-sm'
        default:
          return 'bg-gradient-to-r from-gray-100 to-gray-200 text-gray-700 border border-gray-300'
      }
    },
    getPriorityIcon(priority) {
      switch (priority) {
        case 'high': return 'FireIconSolid'
        case 'medium': return 'ExclamationTriangleIconSolid'
        default: return 'MinusIcon'
      }
    },
    getPriorityLabel(priority) {
      switch (priority) {
        case 'high': return 'Urgente'
        case 'medium': return 'Media'
        default: return 'Normal'
      }
    }
  }
}
</script>

<style scoped>
.task-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 16px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.07);
  border-left: 4px solid #e0e0e0;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid rgba(0, 0, 0, 0.05);
  position: relative;
}

.task-card:hover {
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.12);
  transform: translateY(-3px);
}

.task-card:hover .view-details-btn {
  opacity: 1;
  transform: translate(-50%, -50%) scale(1);
}

.status-pending {
  border-left-color: #ff9800;
}

.status-in-progress {
  border-left-color: #2196f3;
}

.status-completed {
  border-left-color: #4caf50;
}

.task-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.task-title {
  margin: 0;
  color: #2c3e50;
  font-size: 1.2em;
  font-weight: 600;
  line-height: 1.3;
  flex: 1;
  margin-right: 12px;
}

.task-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.action-btn {
  width: 36px;
  height: 36px;
  border: none;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  cursor: pointer;
  background: #f8f9fa;
  color: #6c757d;
}

.action-btn:hover {
  transform: scale(1.05);
}

.view-btn:hover {
  background: #f0f9ff;
  color: #0ea5e9;
  box-shadow: 0 2px 8px rgba(14, 165, 233, 0.2);
}

.edit-btn:hover {
  background: #e3f2fd;
  color: #1976d2;
  box-shadow: 0 2px 8px rgba(25, 118, 210, 0.2);
}

.delete-btn:hover {
  background: #ffebee;
  color: #d32f2f;
  box-shadow: 0 2px 8px rgba(211, 47, 47, 0.2);
}

/* Botón flotante para ver detalles */
.view-details-btn {
  position: relative;
  top: 50%;
  left: 99%;
  transform: translate(-50%, -50%) scale(0.8);
  width: 40px;
  height: 40px;
  background: linear-gradient(135deg, #0ea5e9, #0284c7);
  color: white;
  border: none;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  opacity: 0;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 12px rgba(14, 165, 233, 0.3);
  z-index: 2;
}

.view-details-btn:hover {
  background: linear-gradient(135deg, #0284c7, #0369a1);
  box-shadow: 0 6px 20px rgba(14, 165, 233, 0.4);
  transform: translate(-50%, -50%) scale(1.1);
}

.task-description {
  color: #5a6c7d;
  margin-bottom: 16px;
  line-height: 1.5;
  font-size: 0.95em;
}

.task-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  flex-wrap: wrap;
  gap: 12px;
}

.task-priority {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 0.85em;
  font-weight: 500;
  text-transform: capitalize;
}

.task-datetime {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.task-due-date,
.task-due-time {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.9em;
  color: #6c757d;
  background: #f8f9fa;
  padding: 6px 12px;
  border-radius: 20px;
}

.task-due-time {
  background: linear-gradient(135deg, #e3f2fd, #f8f9fa);
  color: #1976d2;
  font-weight: 500;
}

.task-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.task-status {
  display: flex;
  align-items: center;
  gap: 8px;
}

.status-select {
  padding: 6px 12px;
  border: 1px solid #dee2e6;
  border-radius: 6px;
  font-size: 0.9em;
  background: white;
  color: #495057;
  cursor: pointer;
  transition: all 0.2s ease;
}

.status-select:hover {
  border-color: #adb5bd;
}

.status-select:focus {
  outline: none;
  border-color: #80bdff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.task-tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.tag {
  display: flex;
  align-items: center;
  gap: 4px;
  background: linear-gradient(135deg, #f8f9fa, #e9ecef);
  padding: 4px 10px;
  border-radius: 15px;
  font-size: 0.8em;
  color: #495057;
  border: 1px solid rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: all 0.2s ease;
}

.tag:hover {
  background: linear-gradient(135deg, #e9ecef, #dee2e6);
  transform: translateY(-1px);
}

/* Responsive */
@media (max-width: 768px) {
  .task-card {
    padding: 16px;
  }

  .task-meta,
  .task-footer {
    flex-direction: column;
    align-items: flex-start;
  }

  .task-actions {
    margin-left: auto;
  }

  .task-datetime {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .view-details-btn {
    opacity: 1;
    transform: translate(-50%, -50%) scale(1);
    position: static;
    transform: none;
    margin-top: 12px;
    width: 100%;
    border-radius: 8px;
    height: 36px;
  }
}
</style>
