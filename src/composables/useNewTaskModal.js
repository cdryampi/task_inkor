import { ref } from 'vue'

// Estado global del modal
const isModalOpen = ref(false)

export const useNewTaskModal = () => {
  const openModal = () => {
    console.log('🔧 useNewTaskModal - Abriendo modal')
    isModalOpen.value = true
  }

  const closeModal = () => {
    console.log('🔧 useNewTaskModal - Cerrando modal')
    isModalOpen.value = false
  }

  const resetModal = () => {
    console.log('🔧 useNewTaskModal - Reseteando modal')
    isModalOpen.value = false
  }

  return {
    isModalOpen,
    openModal,
    closeModal,
    resetModal
  }
}
