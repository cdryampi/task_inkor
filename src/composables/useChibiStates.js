import { ref, computed } from 'vue'

export function useChibiStates() {
  // Mapeo de estados a imágenes
  const chibiStates = {
    happy: '/chibi/happy.png',
    excited: '/chibi/excited.png',
    calm: '/chibi/calm.png',
    peaceful: '/chibi/peaceful.png',
    confident: '/chibi/confident.png',
    playful: '/chibi/playful.png',
    thoughtful: '/chibi/thoughtful.png',
    encouraging: '/chibi/encouraging.png'
  }

  // Estado actual del chibi
  const currentState = ref('happy')

  // Imagen actual basada en el estado
  const currentImage = computed(() => {
    return chibiStates[currentState.value] || chibiStates.happy
  })

  // Función para cambiar el estado
  const setChibiState = (estado) => {
    if (chibiStates[estado]) {
      currentState.value = estado
    }
  }

  // Función para obtener imagen por estado
  const getImageByState = (estado) => {
    return chibiStates[estado] || chibiStates.happy
  }

  // Lista de todos los estados disponibles
  const availableStates = Object.keys(chibiStates)

  return {
    currentState,
    currentImage,
    setChibiState,
    getImageByState,
    availableStates,
    chibiStates
  }
}
