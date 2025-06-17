<template>


  <footer class="bg-white border-b border-gray-200 shadow-sm">
      <div class="w-full mx-auto max-w-screen-xl p-4 md:flex md:items-center md:justify-between">
        <span class="text-sm text-gray-500 sm:text-center dark:text-gray-400">
          © 2025 <a href="https://inkor.com" class="hover:underline">InkorTask™</a>. Todos los derechos reservados.
      </span>
      <ul class="flex flex-wrap items-center mt-3 text-sm font-medium text-gray-500 dark:text-gray-400 sm:mt-0">
          <li>
              <router-link
              class="hover:underline me-4 md:me-6"
              to="/"
              title="Inicio"
              >
                Inicio
              </router-link>
          </li>
          <li>
            <router-link
              to="/calendario"
              class="hover:underline me-4 md:me-6"
              title="Calendario"
              >
              Calendario
            </router-link>
          </li>
          <li>
            <router-link
              to="/estadisticas"
              class="hover:underline me-4 md:me-6"
              title="Estadísticas"
              >
              Analytics
            </router-link>
          </li>
          <li>
            <router-link
              to="/mis-tareas-completadas"
              class="hover:underline me-4 md:me-6"
              title="Mis Tareas completadas"
              >
              Mis Tareas completadas
            </router-link>
          </li>
          <li>
            <router-link
              to="/configuracion"
              class="hover:underline me-4 md:me-6"
              title="configuración"
              >
              Configuración
            </router-link>
          </li>
      </ul>
      </div>
  </footer>

</template>

<script setup>

</script>

<style lang="scss" scoped>

</style>
