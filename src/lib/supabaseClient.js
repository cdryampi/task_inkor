import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY
const proxyServer = import.meta.env.VITE_PROXY_SERVER
const useProxy = import.meta.env.VITE_USE_PROXY === 'true'

console.log('🔧 Supabase Config:', {
  url: supabaseUrl,
  useProxy,
  proxyServer: useProxy ? proxyServer : 'disabled'
})

// Configuración del cliente
let clientConfig = {}

if (useProxy && proxyServer) {
  console.log('🔄 Usando modo proxy para Supabase')

  clientConfig = {
    global: {
      fetch: async (url, options = {}) => {
        try {
          // Extraer el path de la URL de Supabase
          const urlObj = new URL(url)
          const path = urlObj.pathname + urlObj.search

          // Construir URL del proxy
          const proxyUrl = `${proxyServer}/api/proxy?path=${encodeURIComponent(path)}`

          console.log('🔄 Proxy request:', {
            original: url,
            path: path,
            proxy: proxyUrl,
            method: options.method || 'GET'
          })

          // Hacer petición al proxy
          const response = await fetch(proxyUrl, {
            ...options,
            headers: {
              ...options.headers,
              'Content-Type': 'application/json'
            }
          })

          console.log('✅ Proxy response:', response.status)
          return response

        } catch (error) {
          console.error('❌ Proxy error:', error)
          throw error
        }
      }
    }
  }
} else {
  console.log('🔗 Usando conexión directa a Supabase')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, clientConfig)

// Export configuration info for debugging
export const supabaseConfig = {
  url: supabaseUrl,
  usingProxy: useProxy,
  proxyServer: useProxy ? proxyServer : null
}
