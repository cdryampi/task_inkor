<template>
  <div class="relative w-full h-full bg-black overflow-hidden border rounded-lg">
    <Renderer
      ref="renderer"
      :width="width"
      :height="height"
      resize="window"
      antialias
      :alpha="true"
      class="w-full h-full"
    >
      <Camera :position="{ x: 0, y: 0.8, z: 2 }" />
      <Scene ref="scene">
        <!-- Luces -->
        <AmbientLight :intensity="0.6" />
        <DirectionalLight
          :position="{ x: 5, y: 5, z: 5 }"
          :intensity="0.8"
          cast-shadow
        />
        <PointLight
          :position="{ x: -5, y: 3, z: 5 }"
          :intensity="0.4"
        />
      </Scene>
    </Renderer>

    <!-- Mensaje tipo burbuja nativo, lateral derecho ocupando hasta 40% -->
    <transition name="fade">
      <div
        v-if="bubbleMessage"
        class="absolute top-4 right-0 max-w-[40%] bg-[var(--color-primary)] text-white px-6 py-3 rounded-l-2xl shadow text-base pointer-events-none z-20 flex items-center"
        style="min-width: 120px;"
      >
        {{ bubbleMessage }}
      </div>
    </transition>

    <!-- Loading overlay -->
    <div v-if="isLoading" class="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center z-10">
      <div class="text-center text-white p-8">
        <div class="w-10 h-10 border-4 border-white border-opacity-30 border-t-white rounded-full animate-spin mx-auto mb-4"></div>
        <p class="text-sm">Cargando modelo... {{ loadingProgress }}%</p>
      </div>
    </div>

    <!-- Error overlay -->
    <div v-if="hasError" class="absolute inset-0 bg-red-500 bg-opacity-20 flex items-center justify-center z-10">
      <div class="text-center text-red-800 p-8">
        <p class="mb-4">Error al cargar el modelo</p>
        <button
          @click="retryLoad"
          class="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors"
        >
          Reintentar
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, onBeforeUnmount } from 'vue'
import { Renderer, Scene, Camera, AmbientLight, DirectionalLight, PointLight } from 'troisjs'
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js'
import * as THREE from 'three'
import { useSupabase } from '@/hooks/supabase.js'

// Props
const props = defineProps({
  width: {
    type: Number,
    default: 500
  },
  height: {
    type: Number,
    default: 500
  },
  modelSrc: {
    type: String,
    default: '/models/waifu_basic.fbx'
  },
  emotion: {
    type: String,
    default: 'idle'
  }
})

// Referencias
const scene = ref(null)
const renderer = ref(null)

// Estado reactivo
const isLoading = ref(true)
const hasError = ref(false)
const loadingProgress = ref(0)
const loadedModel = ref(null)

// Variables de animación
const mixer = ref(null)
const animations = ref([])
const clock = ref(new THREE.Clock())
const animationId = ref(null)

// Mensaje de burbuja
const bubbleMessage = ref('')
let bubbleTimeout = null

// Supabase
const { getRandomMessageByEmotion } = useSupabase()

// Métodos
const loadModel = async () => {
  try {
    isLoading.value = true
    hasError.value = false
    loadingProgress.value = 0

    await nextTick()

    if (!scene.value || !scene.value.scene) {
      throw new Error('Escena no disponible')
    }

    const loader = new FBXLoader()

    const model = await new Promise((resolve, reject) => {
      loader.load(
        props.modelSrc,
        (object) => {
          resolve(object)
        },
        (progress) => {
          if (progress.total > 0) {
            const percentage = Math.round((progress.loaded / progress.total) * 100)
            loadingProgress.value = percentage
          }
        },
        (error) => {
          reject(error)
        }
      )
    })

    // Procesar el modelo
    loadedModel.value = model

    // Configurar animaciones si existen
    if (model.animations && model.animations.length > 0) {
      mixer.value = new THREE.AnimationMixer(model)
      animations.value = model.animations

      // Reproducir la primera animación en loop
      const action = mixer.value.clipAction(model.animations[0])
      action.play()
    }

    // Ajustar posición del modelo
    const box = new THREE.Box3().setFromObject(model)
    const center = box.getCenter(new THREE.Vector3())

    // Centrar y posicionar en el suelo
    model.position.set(-center.x, -box.min.y, -center.z)

    // Escala fija a 1.0 y rotación Y a 0°
    model.scale.setScalar(1.0)
    model.rotation.y = 0

    // Agregar modelo a la escena
    scene.value.scene.add(model)

    // Iniciar loop de animación
    startAnimationLoop()

    isLoading.value = false

    // Mostrar mensaje al cargar modelo
    showBubbleForEmotion('happy')

  } catch (error) {
    console.error('Error cargando modelo:', error)
    hasError.value = true
    isLoading.value = false
  }
}

const showBubbleForEmotion = async (emotion) => {
  // Llama a supabase y muestra el mensaje
  const data = await getRandomMessageByEmotion(emotion)
  if (data && data.length > 0) {
    bubbleMessage.value = data[0].mensaje || '¡Hola!';
    if (bubbleTimeout) clearTimeout(bubbleTimeout)
    bubbleTimeout = setTimeout(() => {
      bubbleMessage.value = ''
    }, 3500)
  }

}

const startAnimationLoop = () => {
  const animate = () => {
    animationId.value = requestAnimationFrame(animate)

    if (mixer.value) {
      const delta = clock.value.getDelta()
      mixer.value.update(delta)
    }
  }
  animate()
}

const stopAnimationLoop = () => {
  if (animationId.value) {
    cancelAnimationFrame(animationId.value)
    animationId.value = null
  }
}

const retryLoad = () => {
  if (loadedModel.value && scene.value?.scene) {
    scene.value.scene.remove(loadedModel.value)
  }
  stopAnimationLoop()
  loadedModel.value = null
  mixer.value = null
  animations.value = []
  loadModel()
}

// Cargar modelo al montar
onMounted(async () => {
  setTimeout(() => {
    loadModel()
  }, 500)
})

// Limpiar al desmontar
onBeforeUnmount(() => {
  stopAnimationLoop()
  if (bubbleTimeout) clearTimeout(bubbleTimeout)
})
</script>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
