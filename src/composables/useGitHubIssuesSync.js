import { ref } from 'vue'

const isLoading = ref(false)
const error = ref(null)
const lastSyncResult = ref(null)

export const useGitHubIssuesSync = () => {

  // **SYNC** - Sincronizar issues de GitHub con tareas (crear nuevas)
  const syncGitHubIssues = async () => {
    isLoading.value = true
    error.value = null

    try {
      console.log('🔄 Iniciando sincronización de issues de GitHub...')

      const proxyServer = import.meta.env.VITE_PROXY_SERVER
      if (!proxyServer) {
        throw new Error('VITE_PROXY_SERVER no está configurado')
      }

      const response = await fetch(`${proxyServer}/api/motivBotLinkIssuesFromGithub`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        }
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.message || `Error HTTP: ${response.status}`)
      }

      const data = await response.json()

      if (!data.success) {
        throw new Error(data.message || 'Error en la sincronización')
      }

      lastSyncResult.value = data.data

      console.log('✅ Sincronización completada:', {
        newTasks: data.data.new_tasks_created,
        existingTasks: data.data.existing_tasks_found,
        processedRepos: data.data.processed_repositories,
        totalIssues: data.data.total_issues_found
      })

      return data.data

    } catch (err) {
      console.error('❌ Error en sincronización de GitHub:', err)
      error.value = err.message
      throw err
    } finally {
      isLoading.value = false
    }
  }

  return {
    // Estado
    isLoading,
    error,
    lastSyncResult,

    // Métodos
    syncGitHubIssues
  }
}
