# 🤖 Task Manager + MotivBot-Chibi

**Task Manager con IA integrada** - Un gestor de tareas moderno escrito en **Vue 3** que se apoya en **Supabase** para el almacenamiento y **OpenAI** para ofrecer asistencia motivacional inteligente a través de MotivBot-Chibi.

![Estado del Proyecto](https://img.shields.io/badge/Estado-85%25%20Completado-brightgreen)
![Vue 3](https://img.shields.io/badge/Vue-3.x-4FC08D)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-412991)

---

## ✨ **Características Principales**

### 📋 **Gestión de Tareas Completa**
- ✅ **CRUD completo** de tareas con título, descripción, prioridad y fechas
- ✅ **Sistema de tags inteligente** con generación automática via OpenAI
- ✅ **Filtros avanzados** por fecha, prioridad, estado y tags
- ✅ **Vista de calendario** integrada con [v-calendar](https://vcalendar.io/)
- ✅ **Vista de tareas completadas** con paginación
- ✅ **Modales responsive** para crear/editar tareas

### 🤖 **MotivBot-Chibi (IA Integrada)**
- 🎭 **Avatar animado** con 8 estados emocionales dinámicos
- 💬 **Mensajes contextuales** personalizados por tarea
- 🏷️ **Generación automática de tags** basada en contenido
- 🧠 **Análisis inteligente** de tareas con OpenAI
- 💾 **Sistema de conversaciones** persistente por tarea
- 🎯 **Estados emocionales adaptativos**: happy, excited, calm, focused, supportive, encouraging, thoughtful, energetic

### 🔧 **Funcionalidades Técnicas**
- 📱 **Diseño completamente responsive** (móvil-first)
- 🌙 **Tema consistente** con Tailwind CSS
- 🔄 **Sistema de notificaciones** con feedback visual
- 🚀 **Proxy API optimizado** para Supabase y OpenAI
- 🧪 **Tests automatizados** incluidos
- ⚡ **Performance optimizada** con lazy loading

---

## 🏗️ **Estructura del Proyecto**

```
task_inkor/
├── 📁 src/
│   ├── 📁 components/
│   │   ├── 📁 tasks/           # Componentes de tareas
│   │   │   ├── ChibiMotivBotComponentTask.vue  # MotivBot widget
│   │   │   ├── TaskCard.vue    # Tarjeta de tarea
│   │   │   └── TaskContainer.vue
│   │   ├── 📁 modals/          # Modales del sistema
│   │   ├── 📁 calendar/        # Componentes de calendario
│   │   ├── 📁 comments/        # Sistema de conversaciones
│   │   └── 📁 ui/              # Componentes base
│   │       └── ChibiAvatar.vue # Avatar animado del bot
│   ├── 📁 views/               # Vistas principales
│   ├── 📁 composables/         # Lógica reutilizable
│   │   ├── useMotivBot.js      # Composable principal del bot
│   │   └── useConversations.js # Gestión de conversaciones
│   ├── 📁 services/            # Servicios de API
│   └── 📁 stores/              # Estado global (Pinia)
├── 📁 proxy/                   # Servidor proxy (Vercel)
│   └── 📁 api/
│       ├── motivBotMessagesOpenIA.js    # API de mensajes IA
│       └── motivBotTaskAddTags.js       # API de generación de tags
├── 📁 sql/                     # Scripts de base de datos
│   ├── 📁 tablas/              # Definiciones de tablas
│   └── 📁 funciones/           # Funciones RPC de Supabase
├── 📁 gpt_actions/             # Integración con ChatGPT
└── 📁 test/                    # Tests automatizados
```

---

## 🚀 **Instalación y Uso**

### **Prerrequisitos**
- **Node.js** 18 o superior
- **Cuenta de Supabase** configurada
- **API Key de OpenAI** (GPT-4 recomendado)
- **Vercel CLI** (para el proxy)

### **1. Configuración del Frontend**

```bash
# Clonar e instalar dependencias
git clone <repository-url>
cd task_inkor
npm install
```

### **2. Variables de Entorno**

Crear `.env` basado en `.env.example`:

```env
# Frontend (Vite)
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu_clave_publica
VITE_PROXY_SERVER=http://localhost:3001

# Desarrollo
VITE_APP_TITLE=Task Manager + MotivBot
```

### **3. Configuración del Proxy**

```bash
cd proxy
npm install

# Crear .env en /proxy/
echo "SUPABASE_URL=https://tu-proyecto.supabase.co" > .env
echo "SUPABASE_ANON_KEY=tu_clave_publica" >> .env
echo "OPENAI_API_KEY=sk-tu-clave-openai" >> .env
```

### **4. Base de Datos (Supabase)**

Ejecutar los scripts SQL en orden:

```sql
-- 1. Crear tablas principales
\i sql/tablas/tasks_table.sql
\i sql/tablas/conversations_table.sql
\i sql/tablas/motivbot_messages_table.sql

-- 2. Crear funciones RPC
\i sql/funciones/motivbot_rpc.sql

-- 3. Configurar políticas RLS (Row Level Security)
\i sql/policies/rls_policies.sql
```

### **5. Desarrollo**

```bash
# Terminal 1: Frontend
npm run dev

# Terminal 2: Proxy
cd proxy
vercel dev
```

La aplicación estará disponible en:
- **Frontend**: `http://localhost:5173`
- **Proxy**: `http://localhost:3001`

---

## 🤖 **MotivBot-Chibi: Características Detalladas**

### **Estados Emocionales**
```javascript
const emotionalStates = {
  happy: '😊 Optimista y alegre',
  excited: '🎉 Energético y entusiasta', 
  calm: '😌 Tranquilo y centrado',
  focused: '🎯 Concentrado en objetivos',
  supportive: '🤗 Comprensivo y empático',
  encouraging: '💪 Motivador y positivo',
  thoughtful: '🤔 Reflexivo y analítico',
  energetic: '⚡ Dinámico y activo'
}
```

### **Generación Inteligente de Tags**
```javascript
// Ejemplo de tags generados automáticamente
const exampleTags = [
  'trabajo', 'personal', 'urgente', 'importante', 
  'reunión', 'llamada', 'desarrollo', 'diseño',
  'revisión', 'planificación', 'investigación'
]
```

### **API de MotivBot**
```javascript
// Endpoints principales
const motivBotAPI = {
  messages: '/api/motivBotMessagesOpenIA',    // Generar mensajes
  tags: '/api/motivBotTaskAddTags',           // Generar tags
  conversations: '/rest/v1/conversations'     // Gestionar conversaciones
}
```

---

## 📊 **Funcionalidades por Vista**

### **🏠 Dashboard Principal** (`/`)
- Lista de tareas con filtros dinámicos
- Widget MotivBot-Chibi integrado
- Acciones rápidas (crear, editar, eliminar)

### **📅 Vista de Calendario** (`/calendario`)
- Calendario mensual con tareas
- Sidebar con tareas del día seleccionado
- Creación rápida desde calendario

### **✅ Tareas Completadas** (`/completadas`)
- Historial de tareas finalizadas
- Paginación avanzada
- Filtros por fecha y prioridad

### **📝 Detalle de Tarea** (`/task/:id`)
- Vista completa de tarea individual
- Sistema de conversaciones con MotivBot
- Historial de estados emocionales
- Estadísticas de interacción

---

## 🧪 **Testing**

```bash
# Ejecutar tests automatizados
npm run test

# Tests específicos de MotivBot
python test/test_motivbot_functions.py

# Linting y formato
npm run lint
npm run format
```

---

## 🚀 **Deploy en Producción**

### **Frontend (Vercel/Netlify)**
```bash
# Build de producción
npm run build

# Preview local
npm run preview
```

### **Proxy (Vercel)**
```bash
cd proxy
vercel --prod
```

### **Variables de Entorno de Producción**
```env
# Frontend
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu_clave_publica
VITE_PROXY_SERVER=https://tu-proxy.vercel.app

# Proxy
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_clave_publica
OPENAI_API_KEY=sk-tu-clave-openai
```

---

## 📋 **Estado del Proyecto**

### **✅ Completado (85%)**
- [x] CRUD completo de tareas
- [x] Sistema de tags inteligente
- [x] MotivBot-Chibi funcional
- [x] Integración con OpenAI
- [x] Vista de calendario
- [x] Sistema de conversaciones
- [x] Diseño responsive
- [x] Proxy API funcionando

### **🔄 En Progreso (10%)**
- [ ] Optimización de performance
- [ ] Tests de integración completos
- [ ] Configuraciones de usuario
- [ ] Cache inteligente de IA

### **⏳ Pendiente (5%)**
- [ ] Notificaciones push
- [ ] Modo offline
- [ ] Exportación de datos
- [ ] Temas personalizables

---

## 🛠️ **Tecnologías Utilizadas**

| Categoría | Tecnología | Versión | Propósito |
|-----------|------------|---------|-----------|
| **Frontend** | Vue 3 | ^3.3.0 | Framework principal |
| **Styling** | Tailwind CSS | ^3.3.0 | Diseño y responsive |
| **Estado** | Pinia | ^2.1.0 | Gestión de estado |
| **Routing** | Vue Router | ^4.2.0 | Navegación SPA |
| **Calendar** | V-Calendar | ^3.0.0 | Componente calendario |
| **Icons** | Heroicons | ^2.0.0 | Iconografía |
| **Backend** | Supabase | - | BaaS completo |
| **IA** | OpenAI GPT-4 | - | Asistente inteligente |
| **Deploy** | Vercel | - | Hosting y proxy |

---

## 🤝 **Contribución**

1. **Fork** el repositorio
2. **Crea** una rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. **Commit** tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. **Push** a la rama (`git push origin feature/nueva-funcionalidad`)
5. **Abre** un Pull Request

### **Convenciones de Código**
- **ESLint** para JavaScript/Vue
- **Prettier** para formato
- **Commits semánticos** recomendados

---

## 📚 **Documentación Adicional**

- 📖 **[TODO.md](TODO.md)** - Lista de tareas y roadmap
- 🔧 **[proxy/README.md](proxy/README.md)** - Documentación del proxy
- 🤖 **[gpt_actions/instrucciones.md](gpt_actions/instrucciones.md)** - Comportamiento de IA
- 📋 **[gpt_actions/motivbot.yaml](gpt_actions/motivbot.yaml)** - API specification

---

## 📄 **Licencia**

Este proyecto es **experimental** y sirve como ejemplo de integración entre Vue, Supabase y servicios de IA. 

**MIT License** - Ver [LICENSE](LICENSE) para más detalles.

---

## 🐛 **Reportar Issues**

Si encuentras algún problema o quieres proponer mejoras:

1. **Revisa** los issues existentes
2. **Crea** un nuevo issue con:
   - Descripción detallada del problema
   - Pasos para reproducir
   - Entorno (navegador, OS, etc.)
   - Screenshots si es aplicable

---

## 🌟 **Reconocimientos**

- **Vue.js Team** por el excelente framework
- **Supabase** por la plataforma BaaS
- **OpenAI** por las capacidades de IA
- **Heroicons** por la iconografía
- **Tailwind CSS** por el sistema de diseño

---

**💡 ¡El proyecto está funcional y listo para usar!** 

Desarrollado con ❤️ para mostrar el potencial de la integración Vue + Supabase + OpenAI.
