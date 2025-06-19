# 📋 TODO.md - Task Manager Inkor + MotivBot-Chibi (2 Semanas)

## 🎯 **Estado Actual**
- ✅ **CRUD básico** funcionando
- ✅ **Calendario** con tareas
- ✅ **Modal crear tarea** con fecha/hora/prioridad
- ✅ **Diseño responsive** básico
- ✅ **Sistema de tags** implementado
- ✅ **Base de datos** con soporte completo para tags
- ✅ **API RPC functions** con filtros por tags
- ✅ **GPT Actions** configurado con tags
- ✅ **Tests** pasando correctamente
- ✅ **MotivBot proxy** con OpenAI integrado

---

## 🔥 **PENDIENTES (Orden de Prioridad)**

### **DÍA 1-2: Funcionalidades Core Completadas**
- ✅ **Modal de edición de tareas**
  - ✅ Componente `EditTaskModal.vue`
  - ✅ Pre-llenar formulario con datos existentes
  - ✅ Reutilizar validaciones del modal crear

- ✅ **Confirmación de eliminación**
  - ✅ Modal simple con confirmación
  - ✅ Mostrar título de la tarea a eliminar

### **DÍA 3-4: UX Básica**
- ✅ **Sistema de notificaciones**
  - ✅ Toast simple para success/error
  - ✅ Feedback visual para acciones

- ✅ **Filtros básicos**
  - ✅ Filtro por prioridad (alta/media/normal)
  - ✅ Filtro por estado (pendiente/completada)
  - ✅ Filtro por tags (nuevo)
  - ✅ Botón "Limpiar filtros"

### **DÍA 5: Mejoras Visuales**
- ✅ **Animaciones simples**
  - ✅ Fade in/out para tareas
  - ✅ Transiciones suaves en modales

- ✅ **Estados visuales**
  - ✅ Loading states
  - ✅ Empty states con ilustraciones

### **DÍA 6: Mobile + Polish**
- ✅ **Optimización móvil**
  - ✅ Modales responsive
  - ✅ Touch gestures básicos
  - ✅ Botones más grandes en móvil

- ✅ **Pulir detalles**
  - ✅ Validaciones de fecha (no fechas pasadas)
  - ✅ Shortcuts de teclado (Esc para cerrar)
  - ✅ Focus management

### **DÍA 7: Testing + Deploy**
- ✅ **Testing manual**
  - ✅ Crear/editar/eliminar tareas
  - ✅ Cambiar fechas y prioridades
  - ✅ Probar en móvil
  - ✅ Tests automatizados para RPC functions

- ✅ **Deploy básico**
  - ✅ Build de producción
  - ✅ Deploy a Vercel/Netlify
  - ✅ Verificar que funciona en producción

---

## 🤖 **NUEVAS FUNCIONALIDADES: MotivBot-Chibi (Semana 2)**

### **DÍA 8-9: Integración MotivBot Core**
- [ ] **Componente MotivBot-Chibi**
  - [ ] `MotivBotWidget.vue` - Widget flotante
  - [ ] `ChibiAvatar.vue` - Avatar animado con estados emocionales
  - [ ] Estados: happy, excited, calm, peaceful, confident, playful, thoughtful, encouraging
  - [ ] Animaciones CSS para cada estado emocional

- [ ] **Chat Interface**
  - [ ] `ChatWindow.vue` - Ventana de chat expandible
  - [ ] `MessageBubble.vue` - Burbujas de mensajes
  - [ ] `TypingIndicator.vue` - Indicador de escritura

### **DÍA 10-11: OpenAI Integration**
- [ ] **Servicio de Mensajes**
  - [ ] `motivBotService.js` - Servicio principal
  - [ ] Integración con `motivBotMessagesOpenIA.js` proxy
  - [ ] Manejo de contexto de tareas y tags
  - [ ] Cache de mensajes frecuentes

- [ ] **Generación Inteligente**
  - [ ] Análisis automático de tags en tareas
  - [ ] Generación de mensajes contextuales
  - [ ] Sistema de fallback a mensajes pre-generados
  - [ ] Detección de estado emocional del usuario

### **DÍA 12: Estados Emocionales y UX**
- [ ] **Sistema de Estados**
  - [ ] Detección automática de estado basado en:
    - Cantidad de tareas pendientes
    - Tareas vencidas
    - Hora del día
    - Patrones de uso
  - [ ] Transiciones suaves entre estados
  - [ ] Persistencia de estado emocional

- [ ] **Interacciones Avanzadas**
  - [ ] Click en Chibi para abrir chat
  - [ ] Mensajes proactivos basados en actividad
  - [ ] Celebraciones al completar tareas
  - [ ] Recordatorios gentiles para tareas vencidas

### **DÍA 13: Mensajes Contextuales**
- [ ] **Base de Datos de Mensajes**
  - [ ] Implementación completa de `chibi_messages`
  - [ ] Seeding con mensajes iniciales por categoría
  - [ ] Sistema de rating de mensajes útiles

- [ ] **Lógica Contextual**
  - [ ] Mensajes específicos por tags de tarea
  - [ ] Mensajes de motivación según prioridad
  - [ ] Mensajes de celebración por completar tareas
  - [ ] Mensajes de apoyo para tareas difíciles

### **DÍA 14: Polish y Testing**
- [ ] **Optimización y Polish**
  - [ ] Optimización de llamadas a OpenAI
  - [ ] Carga lazy del widget MotivBot
  - [ ] Configuración de usuario (activar/desactivar)
  - [ ] Persistencia de conversaciones

- [ ] **Testing Completo**
  - [ ] Tests para componentes MotivBot
  - [ ] Tests de integración con OpenAI
  - [ ] Pruebas de estados emocionales
  - [ ] Testing de rendimiento

---

## 🔧 **TAREAS TÉCNICAS PENDIENTES**

### **Backend/API**
- [ ] **Optimizar funciones RPC**
  - [ ] Cache para tags populares
  - [ ] Paginación mejorada
  - [ ] Índices de base de datos optimizados

- [ ] **Monitoreo**
  - [ ] Logging de errores MotivBot
  - [ ] Métricas de uso de OpenAI
  - [ ] Dashboard de analytics básico

### **Frontend**
- [ ] **Performance**
  - [ ] Code splitting para MotivBot
  - [ ] Lazy loading de componentes
  - [ ] Optimización de bundle size

- [ ] **Accesibilidad**
  - [ ] ARIA labels para MotivBot
  - [ ] Navegación por teclado
  - [ ] Soporte para lectores de pantalla

---

## 🐛 **BUGS CONOCIDOS**
- ✅ ~~Verificar que campos `due_date`, `due_time`, `priority` se guardan en BD~~
- ✅ ~~Manejar errores de conexión a Supabase~~
- ✅ ~~Validar formato de hora correctamente~~
- [ ] Rate limiting para llamadas a OpenAI
- [ ] Manejo de errores cuando OpenAI no responde
- [ ] Validación de tags duplicados

---

## 💡 **NICE TO HAVE (Si sobra tiempo)**
- ✅ ~~Búsqueda básica por título~~
- ✅ ~~Filtros por tags~~
- [ ] Drag & drop para cambiar fechas
- [ ] Dark mode toggle
- [ ] Exportar tareas a PDF/CSV
- [ ] **MotivBot Avanzado:**
  - [ ] Personalización de avatar
  - [ ] Configuración de personalidad
  - [ ] Integración con calendario
  - [ ] Recordatorios inteligentes

---

## 🚫 **NO HACER (Scope Creep)**
- ❌ Subtareas complejas
- ❌ Múltiples usuarios/equipos
- ❌ Notificaciones push complejas
- ❌ Integración con calendarios externos complejos
- ❌ PWA completa con offline
- ❌ MotivBot con voz (text-to-speech)
- ❌ Integración con redes sociales

---

## 📝 **DAILY CHECKLIST - Semana 2**

### **Lunes (Día 8)**: MotivBot Core
- [ ] Widget flotante funcionando
- [ ] Avatar con estados básicos

### **Martes (Día 9)**: Chat Interface  
- [ ] Ventana de chat operativa
- [ ] Mensajes básicos funcionando

### **Miércoles (Día 10)**: OpenAI Integration
- [ ] Proxy funcionando correctamente
- [ ] Mensajes contextuales generándose

### **Jueves (Día 11)**: Estados Emocionales
- [ ] Sistema de detección de estados
- [ ] Animaciones entre estados

### **Viernes (Día 12)**: Mensajes Contextuales
- [ ] Base de datos poblada
- [ ] Lógica contextual funcionando

### **Sábado (Día 13)**: Testing MotivBot
- [ ] Todas las funciones MotivBot probadas
- [ ] Integración completa verificada

### **Domingo (Día 14)**: Deploy Final
- [ ] MotivBot en producción
- [ ] Performance optimizada

---

## 🎯 **CRITERIOS DE ÉXITO - ACTUALIZADOS**

### **Core App (Completado)**
1. ✅ Usuario puede **crear, editar, eliminar** tareas
2. ✅ Usuario puede **asignar fecha, hora, prioridad, tags**
3. ✅ Usuario puede **ver tareas en calendario**
4. ✅ Usuario puede **filtrar tareas por múltiples criterios**
5. ✅ App **funciona en móvil y desktop**
6. ✅ App **está desplegada y accesible**

### **MotivBot-Chibi (Nuevos)**
7. [ ] Usuario puede **interactuar con MotivBot-Chibi**
8. [ ] MotivBot **genera mensajes contextuales** basados en tareas
9. [ ] MotivBot **cambia estados emocionales** según contexto
10. [ ] MotivBot **celebra logros** y **motiva** en dificultades
11. [ ] Sistema **funciona sin interrumpir** la experiencia principal
12. [ ] **Performance optimizada** con IA integrada

---

## 🔄 **FLUJO DE TRABAJO MOTIVBOT**

```
Usuario crea tarea → Tags auto-generados → MotivBot detecta contexto →
Genera mensaje motivacional → Muestra estado emocional apropiado →
Usuario interactúa → MotivBot responde contextualmente
```

---

**🚀 Próximo paso**: Implementar `MotivBotWidget.vue` con estados emocionales básicos y integración con el proxy OpenAI.

**🎨 Diseño**: Avatar Chibi minimalista con 8 estados emocionales claros y animaciones suaves CSS.

**⚡ Performance**: Widget lazy-loaded, cache de mensajes, fallbacks rápidos.