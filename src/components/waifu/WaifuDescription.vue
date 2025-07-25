<template>
  <div class="bg-white dark:bg-white rounded-lg p-4 shadow-md">
    <h4 class="text-4xl font-bold text-primary mb-5">
      {{ title }}
    </h4>
    <p class="text-sm text-black mt-2">
      {{ description }}
    </p>
    <div class="flex flex-wrap gap-2 mt-4">
      <span
        v-for="tag in tags"
        :key="tag"
        class="px-3 py-1 text-xs font-medium rounded-full"
        :class="[
          'bg-primary text-white'
        ]"
      >
        {{ tag }}
      </span>
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  tags: {
    type: Array,
    default: () => []
  }
})
</script>

<style scoped>
</style>
