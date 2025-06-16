import { ref } from 'vue'

// ✅ CREAR ESTADOS SEPARADOS PARA CADA CONTEXTO
const navbarModalState = ref(false)
const calendarModalState = ref(false)

export const useNewTaskModal = (context = 'default') => {
  console.log('🔧 useNewTaskModal - Inicializando con contexto:', context)

  // ✅ SELECCIONAR EL ESTADO CORRECTO SEGÚN EL CONTEXTO
  const getModalState = () => {
    switch (context) {
      case 'navbar':
        return navbarModalState
      case 'calendar':
        return calendarModalState
      default:
        return navbarModalState // Por defecto usar navbar
    }
  }

  const isModalOpen = getModalState()

  const openModal = () => {
    console.log('🔧 useNewTaskModal - Abriendo modal para contexto:', context)
    isModalOpen.value = true
  }

  const closeModal = () => {
    console.log('🔧 useNewTaskModal - Cerrando modal para contexto:', context)
    isModalOpen.value = false
  }

  const resetModal = () => {
    console.log('🔧 useNewTaskModal - Reseteando modal para contexto:', context)
    isModalOpen.value = false
  }

  return {
    isModalOpen,
    openModal,
    closeModal,
    resetModal
  }
}
