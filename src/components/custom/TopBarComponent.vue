<template>
  <div>
    <div class="bg-primary-100 dark:bg-primary-900 text-primary-800 dark:text-primary-200 p-4 shadow-md flex items-center justify-center">
      <div class="flex items-center space-x-2">
        <p class="text-sm font-semibold text-center transition-all delay-150 duration-300 ease-in-out">{{ mensajeActual }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { mensajesTopbar } from '@/data/mensajes_autistas';

const mensaje = ref(mensajesTopbar[Math.floor(Math.random() * mensajesTopbar.length)]);

const mensajeActual = computed(() => {
  return mensaje.value;
});

const cambiarMensaje = () => {
  mensaje.value = mensajesTopbar[Math.floor(Math.random() * mensajesTopbar.length)];
};

// cambiar mensaje cada 10 segundos
setInterval(() => {
  cambiarMensaje();
}, 10000);

</script>

<style lang="scss" scoped>

</style>
