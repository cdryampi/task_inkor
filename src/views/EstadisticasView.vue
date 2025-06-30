<template>
  <div class="container mx-auto p-4">
    <div class="flex items-center gap-3 mb-6">
      <ChartBarIcon class="w-8 h-8 text-primary-600" />
      <h1 class="text-2xl font-bold text-primary-800">Analytics & Estadísticas</h1>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="text-center py-8">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      <p class="mt-2 text-primary-600">Cargando estadísticas...</p>
    </div>

    <!-- Error state -->
    <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
      <div class="flex items-center gap-2">
        <ExclamationTriangleIcon class="w-5 h-5" />
        {{ error }}
      </div>
    </div>

    <!-- Charts -->
    <div v-if="!loading && !error" class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Distribución de Estados - POLAR AREA -->
      <div class="bg-white p-6 rounded-lg shadow-sm border chart-container">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <ChartPieIcon class="w-5 h-5 text-green-600" />
            <h3 class="text-lg font-semibold">Distribución de Tareas</h3>
          </div>
          <!-- ✅ Controles de zoom manual -->
          <div class="flex items-center gap-2">
            <button @click="zoomIn('status')" class="p-1 text-gray-600 hover:text-blue-600 transition-colors">
              <PlusIcon class="w-4 h-4" />
            </button>
            <button @click="zoomOut('status')" class="p-1 text-gray-600 hover:text-blue-600 transition-colors">
              <MinusIcon class="w-4 h-4" />
            </button>
            <button @click="resetZoom('status')" class="p-1 text-gray-600 hover:text-red-600 transition-colors">
              <ArrowsPointingOutIcon class="w-4 h-4" />
            </button>
          </div>
        </div>
        <div class="chart-wrapper">
          <PolarArea ref="statusChart" :data="taskStatusData" :options="statusChartOptions" />
        </div>
      </div>

      <!-- Prioridades - POLAR AREA -->
      <div class="bg-white p-6 rounded-lg shadow-sm border chart-container">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <FlagIcon class="w-5 h-5 text-orange-600" />
            <h3 class="text-lg font-semibold">Por Prioridad</h3>
          </div>
          <div class="flex items-center gap-2">
            <button @click="zoomIn('priority')" class="p-1 text-gray-600 hover:text-blue-600 transition-colors">
              <PlusIcon class="w-4 h-4" />
            </button>
            <button @click="zoomOut('priority')" class="p-1 text-gray-600 hover:text-blue-600 transition-colors">
              <MinusIcon class="w-4 h-4" />
            </button>
            <button @click="resetZoom('priority')" class="p-1 text-gray-600 hover:text-red-600 transition-colors">
              <ArrowsPointingOutIcon class="w-4 h-4" />
            </button>
          </div>
        </div>
        <div class="chart-wrapper">
          <PolarArea ref="priorityChart" :data="priorityData" :options="priorityChartOptions" />
        </div>
      </div>

      <!-- Productividad Semanal -->
      <div class="bg-white p-6 rounded-lg shadow-sm border chart-container md:col-span-2">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <CalendarDaysIcon class="w-5 h-5 text-blue-600" />
            <h3 class="text-lg font-semibold">Productividad - Últimos 7 días</h3>
          </div>
          <div class="flex items-center gap-2">
            <button @click="zoomIn('weekly')" class="p-1 text-gray-600 hover:text-blue-600 transition-colors">
              <PlusIcon class="w-4 h-4" />
            </button>
            <button @click="zoomOut('weekly')" class="p-1 text-gray-600 hover:text-blue-600 transition-colors">
              <MinusIcon class="w-4 h-4" />
            </button>
            <button @click="resetZoom('weekly')" class="p-1 text-gray-600 hover:text-red-600 transition-colors">
              <ArrowsPointingOutIcon class="w-4 h-4" />
            </button>
          </div>
        </div>
        <div class="chart-wrapper-wide">
          <PolarArea ref="weeklyChart" :data="weeklyProductivity" :options="weeklyChartOptions" />
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-if="!loading && !error && statistics.total === 0" class="text-center py-12">
      <ChartBarIcon class="w-16 h-16 text-gray-300 mx-auto mb-4" />
      <p class="text-gray-500 mb-4">No hay tareas para mostrar estadísticas</p>
      <p class="text-sm text-gray-400">
        Crea algunas tareas para ver tus estadísticas
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useSupabase } from '@/hooks/supabase'
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  RadialLinearScale
} from 'chart.js'
import { PolarArea } from 'vue-chartjs'

// ✅ Importar iconos de Heroicons
import {
  ChartBarIcon,
  ChartPieIcon,
  FlagIcon,
  CalendarDaysIcon,
  PlusIcon,
  MinusIcon,
  ArrowsPointingOutIcon,
  ExclamationTriangleIcon
} from '@heroicons/vue/24/outline'

ChartJS.register(
  Title, Tooltip, Legend, ArcElement, RadialLinearScale
)

// ✅ Referencias para los gráficos
const statusChart = ref(null)
const priorityChart = ref(null)
const weeklyChart = ref(null)

// ✅ Estado para zoom
const zoomLevels = ref({
  status: 1,
  priority: 1,
  weekly: 1
})

// ✅ Funciones de zoom
const zoomIn = (chartType) => {
  const oldZoom = zoomLevels.value[chartType]
  zoomLevels.value[chartType] = Math.min(zoomLevels.value[chartType] + 0.2, 3)
  console.log(`🔍 Zoom IN ${chartType}: ${oldZoom} → ${zoomLevels.value[chartType]}`)
}

const zoomOut = (chartType) => {
  const oldZoom = zoomLevels.value[chartType]
  zoomLevels.value[chartType] = Math.max(zoomLevels.value[chartType] - 0.2, 0.5)
  console.log(`🔍 Zoom OUT ${chartType}: ${oldZoom} → ${zoomLevels.value[chartType]}`)
}

const resetZoom = (chartType) => {
  const oldZoom = zoomLevels.value[chartType]
  zoomLevels.value[chartType] = 1
  console.log(`🔄 Reset ${chartType}: ${oldZoom} → ${zoomLevels.value[chartType]}`)
}

// ✅ Usar el hook con getTasksStatistics
const { loading, error, getTasksStatistics } = useSupabase()

// ✅ Estado local para las estadísticas
const statistics = ref({
  pending: 0,
  inProgress: 0,
  completed: 0,
  priority: { high: 0, medium: 0, normal: 0 },
  weeklyProductivity: [],
  total: 0
})

// ✅ Cargar estadísticas al montar usando la función del hook
onMounted(async () => {
  try {
    console.log('🚀 Iniciando carga de estadísticas...')
    const stats = await getTasksStatistics()
    console.log('📊 Raw stats received:', stats)

    statistics.value = stats

    console.log('✅ Statistics state updated:', statistics.value)
    console.log('📈 Weekly productivity:', statistics.value.weeklyProductivity)
  } catch (err) {
    console.error('❌ Error cargando estadísticas:', err)
  }
})

// ✅ Computed para calcular el máximo dinámico
const maxStatusValue = computed(() => {
  const values = [
    statistics.value.pending || 0,
    statistics.value.inProgress || 0,
    statistics.value.completed || 0
  ]
  return Math.max(...values, 1) // Mínimo 1 para evitar división por 0
})

const maxPriorityValue = computed(() => {
  const values = [
    statistics.value.priority?.high || 0,
    statistics.value.priority?.medium || 0,
    statistics.value.priority?.normal || 0
  ]
  return Math.max(...values, 1)
})

const maxWeeklyValue = computed(() => {
  const values = statistics.value.weeklyProductivity?.map(d => d.completed) || [0]
  return Math.max(...values, 1)
})

// ✅ Debug computed properties
const taskStatusData = computed(() => {
  const data = {
    labels: ['Pendientes', 'En Progreso', 'Completadas'],
    datasets: [{
      data: [
        statistics.value.pending || 0,
        statistics.value.inProgress || 0,
        statistics.value.completed || 0
      ],
      backgroundColor: [
        '#fbbf2480',
        '#3b82f680',
        '#10b98180'
      ],
      borderColor: [
        '#fbbf24',
        '#3b82f6',
        '#10b981'
      ],
      borderWidth: 2
    }]
  }
  console.log('📊 Task status data:', data)
  return data
})

const priorityData = computed(() => {
  const data = {
    labels: ['Alta Prioridad', 'Media Prioridad', 'Normal'],
    datasets: [{
      data: [
        statistics.value.priority?.high || 0,
        statistics.value.priority?.medium || 0,
        statistics.value.priority?.normal || 0
      ],
      backgroundColor: [
        '#ef444480',
        '#f59e0b80',
        '#84cc1680'
      ],
      borderColor: [
        '#ef4444',
        '#f59e0b',
        '#84cc16'
      ],
      borderWidth: 2
    }]
  }
  console.log('🎯 Priority data:', data)
  return data
})

const weeklyProductivity = computed(() => {
  const productivity = statistics.value.weeklyProductivity || []
  console.log('📅 Weekly productivity raw:', productivity)

  const data = {
    labels: productivity.map(day => day.label || ''),
    datasets: [{
      data: productivity.map(day => day.completed || 0),
      backgroundColor: [
        '#10b98140', '#3b82f640', '#f59e0b40', '#ef444440',
        '#8b5cf640', '#06b6d440', '#84cc1640'
      ].slice(0, productivity.length),
      borderColor: [
        '#10b981', '#3b82f6', '#f59e0b', '#ef4444',
        '#8b5cf6', '#06b6d4', '#84cc16'
      ].slice(0, productivity.length),
      borderWidth: 2
    }]
  }

  console.log('📈 Weekly chart data:', data)
  return data
})

// ✅ Opciones dinámicas para cada gráfico CON AJUSTE AUTOMÁTICO
const statusChartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom',
      labels: {
        padding: 15,
        usePointStyle: true,
        font: {
          size: Math.round(11 * zoomLevels.value.status)
        }
      }
    },
    tooltip: {
      callbacks: {
        label: function(context) {
          const value = context.raw || context.parsed || 0
          const dataset = context.dataset
          const total = dataset.data.reduce((a, b) => (a || 0) + (b || 0), 0)
          const percentage = total > 0 ? ((value * 100) / total).toFixed(1) : '0.0'
          return `${context.label}: ${value} (${percentage}%)`
        }
      }
    }
  },
  scales: {
    r: {
      beginAtZero: true,
      // ✅ AJUSTE AUTOMÁTICO: El max se basa en el valor máximo de los datos
      max: Math.ceil(maxStatusValue.value * (1.2 / zoomLevels.value.status)), // 20% extra para respiración visual
      ticks: {
        stepSize: Math.max(1, Math.ceil(maxStatusValue.value / (10 * zoomLevels.value.status))),
        backdropColor: 'transparent',
        font: {
          size: Math.round(9 * zoomLevels.value.status)
        },
        showLabelBackdrop: false
      },
      grid: {
        color: '#e5e7eb'
      },
      pointLabels: {
        font: {
          size: Math.round(10 * zoomLevels.value.status)
        }
      }
    }
  }
}))

const priorityChartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom',
      labels: {
        padding: 15,
        usePointStyle: true,
        font: {
          size: Math.round(11 * zoomLevels.value.priority)
        }
      }
    },
    tooltip: {
      callbacks: {
        label: function(context) {
          const value = context.raw || context.parsed || 0
          const dataset = context.dataset
          const total = dataset.data.reduce((a, b) => (a || 0) + (b || 0), 0)
          const percentage = total > 0 ? ((value * 100) / total).toFixed(1) : '0.0'
          return `${context.label}: ${value} (${percentage}%)`
        }
      }
    }
  },
  scales: {
    r: {
      beginAtZero: true,
      // ✅ AJUSTE AUTOMÁTICO para prioridades
      max: Math.ceil(maxPriorityValue.value * (1.2 / zoomLevels.value.priority)),
      ticks: {
        stepSize: Math.max(1, Math.ceil(maxPriorityValue.value / (10 * zoomLevels.value.priority))),
        backdropColor: 'transparent',
        font: {
          size: Math.round(9 * zoomLevels.value.priority)
        },
        showLabelBackdrop: false
      },
      grid: {
        color: '#e5e7eb'
      },
      pointLabels: {
        font: {
          size: Math.round(10 * zoomLevels.value.priority)
        }
      }
    }
  }
}))

const weeklyChartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom',
      labels: {
        padding: 15,
        usePointStyle: true,
        font: {
          size: Math.round(11 * zoomLevels.value.weekly)
        }
      }
    },
    tooltip: {
      callbacks: {
        label: function(context) {
          const value = context.raw || context.parsed || 0
          return `${context.label}: ${value} tareas completadas`
        }
      }
    }
  },
  scales: {
    r: {
      beginAtZero: true,
      // ✅ SÚPER IMPORTANTE: Ajuste automático para productividad semanal
      max: Math.ceil(maxWeeklyValue.value * (1.3 / zoomLevels.value.weekly)), // 30% extra para mejor visualización
      ticks: {
        stepSize: Math.max(1, Math.ceil(maxWeeklyValue.value / (8 * zoomLevels.value.weekly))),
        backdropColor: 'transparent',
        font: {
          size: Math.round(9 * zoomLevels.value.weekly)
        },
        showLabelBackdrop: false
      },
      grid: {
        color: '#e5e7eb'
      },
      pointLabels: {
        font: {
          size: Math.round(10 * zoomLevels.value.weekly)
        }
      }
    }
  }
}))
</script>

<style scoped>
/* ✅ Contenedores con altura fija */
.chart-container {
  height: 400px;
  max-height: 400px;
  overflow: hidden;
  transition: transform 0.2s ease;
}

.chart-container:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.1);
}

/* ✅ Wrapper del gráfico con altura controlada */
.chart-wrapper {
  height: 280px;
  max-height: 280px;
  width: 100%;
  position: relative;
  cursor: grab;
}

.chart-wrapper:active {
  cursor: grabbing;
}

.chart-wrapper-wide {
  height: 300px;
  max-height: 300px;
  width: 100%;
  position: relative;
  cursor: grab;
}

.chart-wrapper-wide:active {
  cursor: grabbing;
}

/* ✅ Forzar altura en el canvas */
:deep(.chartjs-render-monitor) {
  height: 100% !important;
  max-height: 280px !important;
}

:deep(.chart-wrapper-wide .chartjs-render-monitor) {
  max-height: 300px !important;
}

/* ✅ Responsive para móviles */
@media (max-width: 768px) {
  .chart-container {
    height: 350px;
    max-height: 350px;
  }

  .chart-wrapper,
  .chart-wrapper-wide {
    height: 250px;
    max-height: 250px;
  }

  :deep(.chartjs-render-monitor) {
    max-height: 250px !important;
  }
}

/* ✅ Efectos visuales para zoom */
.chart-wrapper:hover,
.chart-wrapper-wide:hover {
  background: linear-gradient(145deg, #f8fafc, #f1f5f9);
  border-radius: 8px;
}
</style>
