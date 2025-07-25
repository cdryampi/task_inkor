/**
 * Sistema de logging centralizado para la aplicación
 * Solo muestra logs en desarrollo, excepto errores críticos
 */

const isDevelopment = import.meta.env.DEV
const isProduction = import.meta.env.PROD

// Configuración de colores para consola
const colors = {
  info: '#3B82F6',      // Azul
  success: '#10B981',   // Verde
  warn: '#F59E0B',      // Amarillo
  error: '#EF4444',     // Rojo
  debug: '#8B5CF6'      // Púrpura
}

// Función helper para formatear timestamp
const getTimestamp = () => {
  return new Date().toLocaleTimeString('es-ES', {
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    fractionalSecondDigits: 3
  })
}

// Función helper para formatear mensajes
const formatMessage = (level, message) => {
  const timestamp = getTimestamp()
  return `[${timestamp}] ${level.toUpperCase()}: ${message}`
}

export const logger = {
  /**
   * Log de información general
   */
  info: (message, ...args) => {
    if (isDevelopment) {
      console.log(
        `%c${formatMessage('info', message)}`,
        `color: ${colors.info}; font-weight: bold;`,
        ...args
      )
    }
  },

  /**
   * Log de operaciones exitosas
   */
  success: (message, ...args) => {
    if (isDevelopment) {
      console.log(
        `%c✅ ${formatMessage('success', message)}`,
        `color: ${colors.success}; font-weight: bold;`,
        ...args
      )
    }
  },

  /**
   * Log de advertencias
   */
  warn: (message, ...args) => {
    if (isDevelopment) {
      console.warn(
        `%c⚠️ ${formatMessage('warn', message)}`,
        `color: ${colors.warn}; font-weight: bold;`,
        ...args
      )
    }
  },

  /**
   * Log de errores - SIEMPRE se muestran
   */
  error: (message, ...args) => {
    console.error(
      `%c❌ ${formatMessage('error', message)}`,
      `color: ${colors.error}; font-weight: bold;`,
      ...args
    )

    // En producción, podrías enviar a un servicio de monitoreo
    if (isProduction) {
      // TODO: Integrar con Sentry, LogRocket, etc.
      // trackError(message, ...args)
    }
  },

  /**
   * Log de debugging detallado
   */
  debug: (message, ...args) => {
    if (isDevelopment) {
      console.log(
        `%c🐛 ${formatMessage('debug', message)}`,
        `color: ${colors.debug}; font-weight: normal;`,
        ...args
      )
    }
  },

  /**
   * Log de rendimiento/timing
   */
  perf: (message, startTime, ...args) => {
    if (isDevelopment) {
      const duration = performance.now() - startTime
      console.log(
        `%c⏱️ ${formatMessage('perf', `${message} (${duration.toFixed(2)}ms)`)}`,
        `color: ${colors.info}; font-style: italic;`,
        ...args
      )
    }
  },

  /**
   * Grupo de logs (para agrupar logs relacionados)
   */
  group: (title, collapsed = false) => {
    if (isDevelopment) {
      const method = collapsed ? console.groupCollapsed : console.group
      method(`%c📂 ${title}`, `color: ${colors.info}; font-weight: bold;`)
    }
  },

  /**
   * Cerrar grupo de logs
   */
  groupEnd: () => {
    if (isDevelopment) {
      console.groupEnd()
    }
  },

  /**
   * Log de tabla (útil para arrays/objetos)
   */
  table: (data, columns) => {
    if (isDevelopment) {
      console.table(data, columns)
    }
  },

  /**
   * Log de datos complejos con formato mejorado
   */
  data: (label, data) => {
    if (isDevelopment) {
      console.log(
        `%c📊 ${formatMessage('data', label)}`,
        `color: ${colors.debug}; font-weight: bold;`
      )
      console.log(data)
    }
  }
}

// Funciones especializadas para casos comunes
export const loggers = {
  /**
   * Logger específico para operaciones de API
   */
  api: {
    request: (method, url, payload) => {
      logger.group(`🌐 API ${method.toUpperCase()} ${url}`)
      logger.info(`Enviando request`)
      if (payload) logger.data('Payload', payload)
    },

    response: (status, data, duration) => {
      logger.success(`Response ${status} recibida`)
      if (data) logger.data('Response data', data)
      if (duration) logger.perf('Request completado', duration)
      logger.groupEnd()
    },

    error: (method, url, error) => {
      logger.group(`💥 API Error ${method.toUpperCase()} ${url}`)
      logger.error('Request falló', error)
      logger.groupEnd()
    }
  },

  /**
   * Logger específico para el estado de Vue
   */
  vue: {
    component: (name, action, data) => {
      logger.debug(`🎨 ${name} - ${action}`, data)
    },

    lifecycle: (component, hook) => {
      logger.debug(`🔄 ${component} - ${hook}`)
    },

    computed: (name, value) => {
      logger.debug(`💭 Computed ${name}:`, value)
    }
  },

  /**
   * Logger específico para tareas
   */
  tasks: {
    loaded: (count) => {
      logger.success(`${count} tareas cargadas`)
    },

    created: (task) => {
      logger.success(`Tarea creada: "${task.title}"`)
    },

    updated: (task) => {
      logger.success(`Tarea actualizada: "${task.title}"`)
    },

    deleted: (taskId) => {
      logger.success(`Tarea eliminada: ID ${taskId}`)
    },

    filtered: (total, filtered, filters) => {
      logger.info(`Filtros aplicados: ${filtered}/${total} tareas`, filters)
    }
  }
}

// Export por defecto
export default logger
