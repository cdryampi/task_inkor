<template>
  <div class="app-container min-h-screen">
    <div class="max-w-4xl mx-auto p-6">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gradient-primary mb-2 flex items-center gap-2">
          <CogIcon class="w-8 h-8" />
          Configuración
        </h1>
        <p class="text-gray-600">
          Gestiona las preferencias y sincronización de tu MotivBot
        </p>
      </div>

      <!-- Sección GitHub Sync -->
      <div class="card mb-8 p-6">
        <div class="flex items-center gap-3 mb-6">
          <div class="w-10 h-10 bg-gradient-ai rounded-full flex items-center justify-center">
            <CodeBracketSquareIcon class="text-white w-5 h-5" />
          </div>
          <div>
            <h2 class="text-xl font-semibold text-gray-800">
              Sincronización GitHub
            </h2>
            <p class="text-sm text-gray-600">
              Convierte tus issues de GitHub en tareas automáticamente
            </p>
            <small class="text-xs text-gray-500 mt-1">
              <span class="font-medium">Nota:</span> Esta función puede tardar un poco dependiendo de la cantidad de repositorios y issues.
            </small>
          </div>
        </div>

        <!-- Estado de sincronización -->
        <div v-if="lastSyncResult" class="mb-6 p-4 rounded-12 border">
          <div v-if="lastSyncResult.new_tasks_created > 0"
               class="bg-green-50 border-green-200 text-green-800">
            <div class="flex items-center gap-2 font-medium mb-2">
              <CheckCircleIcon class="text-green-600 w-5 h-5" />
              ¡Sincronización exitosa!
            </div>
            <p class="text-sm">
              {{ lastSyncResult.new_tasks_created }} nuevas tareas creadas de
              {{ lastSyncResult.total_issues_found }} issues encontrados
            </p>
            <p class="text-xs text-green-600 mt-1 flex items-center gap-1">
              <FolderOpenIcon class="w-4 h-4" />
              {{ lastSyncResult.processed_repositories }} repositorios procesados
            </p>
          </div>

          <div v-else class="bg-blue-50 border-blue-200 text-blue-800">
            <div class="flex items-center gap-2 font-medium mb-2">
              <CheckBadgeIcon class="text-blue-600 w-5 h-5" />
              Todo actualizado
            </div>
            <p class="text-sm">
              {{ lastSyncResult.total_issues_found }} issues revisados,
              {{ lastSyncResult.existing_tasks_found }} tareas ya existían
            </p>
            <p class="text-xs text-blue-600 mt-1 flex items-center gap-1">
              <FolderOpenIcon class="w-4 h-4" />
              {{ lastSyncResult.processed_repositories }} repositorios procesados
            </p>
          </div>
        </div>

        <!-- ✅ Estado de actualización de tareas -->
        <div v-if="todayTasks.length > 0" class="mb-6 p-4 rounded-12 border bg-purple-50 border-purple-200 text-purple-800">
          <div class="flex items-center gap-2 font-medium mb-2">
            <ArrowPathIcon class="text-purple-600 w-5 h-5" />
            Tareas activas actualizadas
          </div>
          <p class="text-sm">
            {{ todayTasks.length }} tareas activas encontradas y fechas actualizadas
          </p>
          <p class="text-xs text-purple-600 mt-1">
            Estados: pending, in_progress, on_hold
          </p>
        </div>

        <!-- Error -->
        <div v-if="error || taskError" class="mb-6 p-4 bg-red-50 border border-red-200 rounded-12">
          <div class="flex items-center gap-2 text-red-800 font-medium mb-1">
            <ExclamationCircleIcon class="text-red-600 w-5 h-5" />
            Error
          </div>
          <p class="text-sm text-red-700">{{ error || taskError }}</p>
        </div>

        <!-- ✅ Botones de sincronización -->
        <div class="flex flex-col gap-4">
          <!-- Botón principal de sincronización -->
          <div class="flex items-center gap-4">
            <button
              @click="handleSync"
              :disabled="isLoading || isLoadingTasks"
              class="btn btn-primary btn-lg glow-on-hover flex items-center gap-2"
            >
              <ArrowPathIcon
                v-if="isLoading"
                class="animate-spin w-5 h-5"
              />
              <LinkIcon
                v-else
                class="w-5 h-5"
              />
              <span v-if="isLoading">Sincronizando...</span>
              <span v-else>Crear Nuevas Tareas desde GitHub</span>
            </button>

            <div class="text-sm text-gray-500">
              <p class="flex items-center gap-1">
                <RocketLaunchIcon class="w-4 h-4" />
                Conecta automáticamente tus repositorios
              </p>
              <p class="text-xs flex items-center gap-1">
                <TagIcon class="w-3 h-3" />
                Solo crea tareas nuevas, no duplica
              </p>
            </div>
          </div>

          <!-- ✅ Botón de actualización usando useTodayTasks -->
          <div class="flex items-center gap-4">
            <button
              @click="handleUpdateTasks"
              :disabled="isLoading || isLoadingTasks"
              class="btn btn-secondary btn-lg flex items-center gap-2"
            >
              <ArrowPathIcon
                v-if="isLoadingTasks"
                class="animate-spin w-5 h-5"
              />
              <ArrowPathIcon
                v-else
                class="w-5 h-5"
              />
              <span v-if="isLoadingTasks">Actualizando...</span>
              <span v-else">Actualizar Fechas de Tareas Activas</span>
            </button>

            <div class="text-sm text-gray-500">
              <p class="flex items-center gap-1">
                <ArrowPathIcon class="w-4 h-4" />
                Actualiza fecha de tareas pending/in_progress/on_hold
              </p>
              <p class="text-xs flex items-center gap-1">
                <CheckCircleIcon class="w-3 h-3" />
                Marca como "vistas hoy"
              </p>
            </div>
          </div>
        </div>

        <!-- Info adicional -->
        <div class="mt-6 p-4 bg-gray-50 rounded-12 border border-gray-200">
          <h3 class="text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
            <InformationCircleIcon class="text-blue-500 w-4 h-4" />
            ¿Cómo funciona?
          </h3>
          <ul class="text-xs text-gray-600 space-y-1">
            <li class="flex items-center gap-2">
              <MagnifyingGlassIcon class="text-gray-400 flex-shrink-0 w-4 h-4" />
              <strong>Crear Nuevas:</strong> Recorre todos tus repositorios y crea tareas para nuevos issues
            </li>
            <li class="flex items-center gap-2">
              <ArrowPathIcon class="text-gray-400 flex-shrink-0 w-4 h-4" />
              <strong>Actualizar Fechas:</strong> Actualiza el timestamp de todas las tareas activas
            </li>
            <li class="flex items-center gap-2">
              <ShieldCheckIcon class="text-gray-400 flex-shrink-0 w-4 h-4" />
              <strong>Sin duplicados:</strong> Evita crear tareas repetidas automáticamente
            </li>
            <li class="flex items-center gap-2">
              <HashtagIcon class="text-gray-400 flex-shrink-0 w-4 h-4" />
              <strong>Organización:</strong> Añade tags automáticos para fácil identificación
            </li>
          </ul>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { useGitHubIssuesSync } from '@/composables/useGitHubIssuesSync'
import { useTodayTasks } from '@/composables/useTodayTasks' // ✅ Importar el composable
import {
  CodeBracketSquareIcon,
  CheckCircleIcon,
  CheckBadgeIcon,
  ExclamationCircleIcon,
  ArrowPathIcon,
  LinkIcon,
  RocketLaunchIcon,
  TagIcon,
  InformationCircleIcon,
  MagnifyingGlassIcon,
  DocumentPlusIcon,
  ShieldCheckIcon,
  HashtagIcon,
  FolderOpenIcon,
  CogIcon
} from '@heroicons/vue/24/outline'

// Composable de sincronización GitHub
const {
  isLoading,
  error,
  lastSyncResult,
  syncGitHubIssues
} = useGitHubIssuesSync()

// ✅ Composable de tareas de hoy
const {
  todayTasks,
  isLoading: isLoadingTasks,
  error: taskError,
  getTodayTasks
} = useTodayTasks()

// Manejar sincronización (crear nuevas)
const handleSync = async () => {
  try {
    console.log('🚀 Iniciando sincronización manual...')
    await syncGitHubIssues()
    console.log('✅ Sincronización completada desde configuración')
  } catch (err) {
    console.error('❌ Error en sincronización manual:', err)
  }
}

// ✅ Manejar actualización de fechas usando useTodayTasks
const handleUpdateTasks = async () => {
  try {
    console.log('🔄 Actualizando fechas de tareas activas...')
    await getTodayTasks()
    console.log('✅ Fechas de tareas actualizadas desde configuración')
  } catch (err) {
    console.error('❌ Error en actualización de tareas:', err)
  }
}
</script>

<style scoped>
/* Animación personalizada para el spinner */
.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
