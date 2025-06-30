<template>
  <div class="app-container min-h-screen">
    <div class="max-w-4xl mx-auto p-6">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gradient-primary mb-2">
          ⚙️ Configuración
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

        <!-- Error -->
        <div v-if="error" class="mb-6 p-4 bg-red-50 border border-red-200 rounded-12">
          <div class="flex items-center gap-2 text-red-800 font-medium mb-1">
            <ExclamationCircleIcon class="text-red-600 w-5 h-5" />
            Error en sincronización
          </div>
          <p class="text-sm text-red-700">{{ error }}</p>
        </div>

        <!-- Botón de sincronización -->
        <div class="flex items-center gap-4">
          <button
            @click="handleSync"
            :disabled="isLoading"
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
            <span v-else>Sincronizar Issues GitHub</span>
          </button>

          <div class="text-sm text-gray-500">
            <p class="flex items-center gap-1">
              <RocketLaunchIcon class="w-4 h-4" />
              Conecta automáticamente tus repositorios
            </p>
            <p class="text-xs flex items-center gap-1">
              <TagIcon class="w-3 h-3" />
              Se añadirán como tareas con tag especial
            </p>
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
              Recorre todos tus repositorios de GitHub
            </li>
            <li class="flex items-center gap-2">
              <DocumentPlusIcon class="text-gray-400 flex-shrink-0 w-4 h-4" />
              Convierte los issues en tareas con contexto completo
            </li>
            <li class="flex items-center gap-2">
              <ShieldCheckIcon class="text-gray-400 flex-shrink-0 w-4 h-4" />
              Evita duplicados automáticamente
            </li>
            <li class="flex items-center gap-2">
              <ArrowPathIcon class="text-gray-400 flex-shrink-0 w-4 h-4" />
              Mantiene sincronizado el estado (abierto/cerrado)
            </li>
            <li class="flex items-center gap-2">
              <HashtagIcon class="text-gray-400 flex-shrink-0 w-4 h-4" />
              Añade tags automáticos para organización
            </li>
          </ul>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { useGitHubIssuesSync } from '@/composables/useGitHubIssuesSync'
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
  FolderOpenIcon
} from '@heroicons/vue/24/outline'

// Composable de sincronización GitHub
const {
  isLoading,
  error,
  lastSyncResult,
  syncGitHubIssues
} = useGitHubIssuesSync()

// Manejar sincronización
const handleSync = async () => {
  try {
    console.log('🚀 Iniciando sincronización manual...')
    await syncGitHubIssues()
    console.log('✅ Sincronización completada desde configuración')
  } catch (err) {
    console.error('❌ Error en sincronización manual:', err)
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
