import { ref } from 'vue'

// Estado global del modal
const isModalOpen = ref(false)

export const useNewTaskModal = () => {
  const openModal = () => {
    isModalOpen.value = true
  }

  const closeModal = () => {
    isModalOpen.value = false
  }

  return {
    isModalOpen,
    openModal,
    closeModal
  }
}
