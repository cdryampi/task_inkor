<template>
  <div class="w-full max-w-screen-xl mx-auto p-5 mb-5 bg-gray-50">
        <!-- Hero Section -->
    <div class="flex flex-col items-center justify-center py-8 px-4 sm:px-8">
      <h1 class="mb-2 text-5xl font-extrabold text-primary text-center">Tu Waifu Virtual</h1>
      <p class="mb-4 text-gray-600 text-center max-w-2xl">
        Elige una emoción para tu waifu y observa cómo cambia su expresión y actitud en 3D. Minimalismo, claridad y tecnología para tu día a día.
      </p>
    </div>
  </div>
  <div class="border-t-2 p-1 border-primary">

  </div>
  <div class="w-full max-w-screen-xl mx-auto p-5 mt-5">


    <!-- Tabs de emociones -->
    <ul
      class="flex flex-wrap text-sm font-medium text-center"
      role="tablist"
    >
      <li
        v-for="(emotion, key) in emotionData"
        :key="key"
        class="me-2"
      >
        <button
          :id="`${key}-tab`"
          :data-tabs-target="`#${key}`"
          type="button"
          role="tab"
          :aria-controls="key"
          :aria-selected="selectedEmotion === key"
          @click="selectEmotion(key)"
          :class="[
            'inline-block p-3 rounded-t-lg font-semibold transition-colors duration-200',
            selectedEmotion === key
              ? 'text-white bg-[var(--color-primary)]'
              : 'text-gray-500 hover:text-[var(--color-primary)] hover:bg-gray-100'
          ]"
        >
          {{ emotion.title }}
        </button>
      </li>
    </ul>

    <!-- Contenido -->
    <div class="grid grid-cols-6 gap-4 p-4 bg-white md:p-8">
      <!-- Modelo (col-6) -->
      <div class="col-span-6 lg:col-span-3">
        <div class="rounded-lg p-4 h-80 flex items-center justify-center">
          <WaifuContainer
            :width="500"
            :height="500"
            :model-src="currentModel"
            :emotion="selectedEmotion"
          />
        </div>
      </div>

      <!-- Información (col-6) -->
      <div class="col-span-6 lg:col-span-3 flex items-center">
        <WaifuDescription
          :title="emotionData[selectedEmotion]?.title"
          :description="emotionData[selectedEmotion]?.description"
          :tags="emotionData[selectedEmotion]?.tags"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import WaifuContainer from './WaifuContainer.vue'
import WaifuDescription from './WaifuDescription.vue'
import emotionMap from '@/data/emotionMap.js'

// Estado reactivo
const selectedEmotion = ref('idle')
const emotionData = ref(emotionMap)

// Computed
const currentModel = computed(() => {
  return `/models/${emotionData.value[selectedEmotion.value]?.file || 'waifu_basic.fbx'}`
})

// Métodos
const selectEmotion = (emotionKey) => {
  selectedEmotion.value = emotionKey
}
</script>

<style scoped>
/* Minimalista: solo color primario y blanco */
.btn-primary {
  background: var(--color-primary);
  color: #fff;
}
.btn-primary:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}
</style>
