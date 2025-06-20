<template>
<div class="flex h-screen justify-center items-center dark:bg-slate-800">
    <div class="mx-auto mt-10 flex justify-center px-4 sm:mt-12 sm:px-6 md:mt-16 lg:mt-20 lg:px-8">
        <div class="text-center">
            <h1
                class="text-4xl font-extrabold tracking-tight text-gray-900 dark:text-slate-200 sm:text-5xl md:text-6xl">
                <span class="block xl:inline"><span class="mb-1 block">Organiza tu vida</span>
                <span class="bg-gradient-to-r from-emerald-400 to-blue-600 bg-clip-text text-transparent">
                    sin perder la cordura
                </span>
                </span>
                <div class="mt-2">con tu coach personal
                    <span class="relative mt-3 whitespace-nowrap text-emerald-600">
                        <svg aria-hidden="true" viewBox="0 0 418 42"
                            class="absolute top-3/4 left-0 right-0 m-auto h-[0.58em] w-fit fill-emerald-400/50"
                            preserveAspectRatio="none">
                            <path
                                d="M203.371.916c-26.013-2.078-76.686 1.963-124.73 9.946L67.3 12.749C35.421 18.062 18.2 21.766 6.004 25.934 1.244 27.561.828 27.778.874 28.61c.07 1.214.828 1.121 9.595-1.176 9.072-2.377 17.15-3.92 39.246-7.496C123.565 7.986 157.869 4.492 195.942 5.046c7.461.108 19.25 1.696 19.17 2.582-.107 1.183-7.874 4.31-25.75 10.366-21.992 7.45-35.43 12.534-36.701 13.884-2.173 2.308-.202 4.407 4.442 4.734 2.654.187 3.263.157 15.593-.78 35.401-2.686 57.944-3.488 88.365-3.143 46.327.526 75.721 2.23 130.788 7.584 19.787 1.924 20.814 1.98 24.557 1.332l.066-.011c1.201-.203 1.53-1.825.399-2.335-2.911-1.31-4.893-1.604-22.048-3.261-57.509-5.556-87.871-7.360-132.059-7.842-23.239-.254-33.617-.116-50.627.674-11.629.54-42.371 2.494-46.696 2.967-2.359.259 8.133-3.625 26.504-9.81 23.239-7.825 27.934-10.149 28.304-14.005.417-4.348-3.529-6-16.878-7.066Z">
                            </path>
                        </svg>
                        <span class="relative flex items-center space-x-1">
                            <span>que no te juzga</span>
                            <ComputerDesktopIcon class="w-25 h-25" />
                        </span>
                    </span>
                </div>
            </h1>
            <p class="mx-auto mt-3 max-w-2xl text-lg text-gray-500 dark:text-slate-400 sm:mt-5 md:mt-5">
                <span class="font-medium text-gray-700 dark:text-slate-300">TaskInkor</span> es tu gestor de tareas con
                <span class="italic">alma artificial</span>. Organiza tu caos diario mientras recibes consejos, ánimos
                y comentarios sorprendentemente perspicaces de tu nuevo mejor amigo digital.
            </p>

            <!-- Features mini -->
            <div class="mt-6 flex flex-wrap justify-center gap-4 text-sm text-gray-600 dark:text-slate-400">
                <div class="flex items-center space-x-2">
                    <ClipboardDocumentListIcon class="w-5 h-5 text-emerald-600" />
                    <span>Gestión intuitiva</span>
                </div>
                <div class="flex items-center space-x-2">
                    <SparklesIcon class="w-5 h-5 text-blue-600" />
                    <span>Consejos AI</span>
                </div>
                <div class="flex items-center space-x-2">
                    <HeartIcon class="w-5 h-5 text-red-500" />
                    <span>Soporte emocional</span>
                </div>
                <div class="flex items-center space-x-2">
                    <RocketLaunchIcon class="w-5 h-5 text-purple-600" />
                    <span>Sin procrastinación</span>
                </div>
            </div>

            <div class="mt-8 sm:mt-10 sm:flex sm:justify-center">
                <div class="rounded-md shadow">
                    <router-link
                        to="/mis-tareas"
                        class="flex w-full items-center justify-center space-x-2 rounded-md border border-transparent bg-emerald-600 px-8 py-3 text-base font-medium text-white hover:bg-emerald-700 transition-colors md:py-4 md:px-10 md:text-lg"
                    >
                        <span>Empezar a organizarme</span>
                        <ArrowRightIcon class="w-5 h-5" />
                    </router-link>
                </div>
            </div>

            <!-- Stats divertidas con iconos de chibis -->
            <div class="mt-12 grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
                <div class="p-3 bg-white rounded-lg">
                    <div class="flex justify-center mb-2">
                        <img src="/images/chibi/happy.png" alt="Happy Chibi" class="w-25 h-25 object-contain" />
                    </div>
                    <div class="text-2xl font-bold text-emerald-600">0</div>
                    <div class="text-xs text-gray-500 dark:text-slate-400">Crisis existenciales</div>
                </div>
                <div class="p-3 bg-white rounded-lg">
                    <div class="flex justify-center mb-2">
                        <img src="/images/chibi/excited.png" alt="Excited Chibi" class="w-25 h-25 object-contain" />
                    </div>
                    <div class="text-2xl font-bold text-blue-600">∞</div>
                    <div class="text-xs text-gray-500 dark:text-slate-400">Paciencia del AI</div>
                </div>
                <div class="p-3 bg-white rounded-lg">
                    <div class="flex justify-center mb-2">
                        <img src="/images/chibi/calm.png" alt="Calm Chibi" class="w-25 h-25 object-contain" />
                    </div>
                    <div class="text-2xl font-bold text-purple-600">100%</div>
                    <div class="text-xs text-gray-500 dark:text-slate-400">Libre de juicios</div>
                </div>
                <div class="p-3 bg-white rounded-lg">
                    <div class="flex justify-center mb-2">
                        <img src="/images/chibi/peaceful.png" alt="Peaceful Chibi" class="w-25 h-25 object-contain" />
                    </div>
                    <div class="text-2xl font-bold text-orange-600">24/7</div>
                    <div class="text-xs text-gray-500 dark:text-slate-400">Disponibilidad</div>
                </div>
            </div>
        </div>
    </div>
</div>
</template>

<script setup>
import { ref } from 'vue'
import {
    ClipboardDocumentListIcon,
    SparklesIcon,
    HeartIcon,
    RocketLaunchIcon,
    ArrowRightIcon,
    ComputerDesktopIcon
} from '@heroicons/vue/24/outline'
</script>

<style lang="scss" scoped>
</style>
