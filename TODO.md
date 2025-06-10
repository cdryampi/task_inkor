# 📋 TODO.md - Task Manager Inkor (1 Semana)

## 🎯 **Estado Actual**
- ✅ **CRUD básico** funcionando
- ✅ **Calendario** con tareas
- ✅ **Modal crear tarea** con fecha/hora/prioridad
- ✅ **Diseño responsive** básico

---

## 🔥 **PENDIENTES (Orden de Prioridad)**

### **DÍA 1-2: Funcionalidades Core**
- [ ] **Modal de edición de tareas**
  - [ ] Componente `EditTaskModal.vue`
  - [ ] Pre-llenar formulario con datos existentes
  - [ ] Reutilizar validaciones del modal crear

- [ ] **Confirmación de eliminación**
  - [ ] Modal simple con confirmación
  - [ ] Mostrar título de la tarea a eliminar

### **DÍA 3-4: UX Básica**
- [ ] **Sistema de notificaciones**
  - [ ] Toast simple para success/error
  - [ ] Feedback visual para acciones

- [ ] **Filtros básicos**
  - [ ] Filtro por prioridad (alta/media/normal)
  - [ ] Filtro por estado (pendiente/completada)
  - [ ] Botón "Limpiar filtros"

### **DÍA 5: Mejoras Visuales**
- [ ] **Animaciones simples**
  - [ ] Fade in/out para tareas
  - [ ] Transiciones suaves en modales

- [ ] **Estados visuales**
  - [ ] Loading states
  - [ ] Empty states con ilustraciones

### **DÍA 6: Mobile + Polish**
- [ ] **Optimización móvil**
  - [ ] Modales responsive
  - [ ] Touch gestures básicos
  - [ ] Botones más grandes en móvil

- [ ] **Pulir detalles**
  - [ ] Validaciones de fecha (no fechas pasadas)
  - [ ] Shortcuts de teclado (Esc para cerrar)
  - [ ] Focus management

### **DÍA 7: Testing + Deploy**
- [ ] **Testing manual**
  - [ ] Crear/editar/eliminar tareas
  - [ ] Cambiar fechas y prioridades
  - [ ] Probar en móvil

- [ ] **Deploy básico**
  - [ ] Build de producción
  - [ ] Deploy a Vercel/Netlify
  - [ ] Verificar que funciona en producción

---

## 🐛 **BUGS CONOCIDOS**
- [ ] Verificar que campos `due_date`, `due_time`, `priority` se guardan en BD
- [ ] Manejar errores de conexión a Supabase
- [ ] Validar formato de hora correctamente

---

## 💡 **NICE TO HAVE (Si sobra tiempo)**
- [ ] Búsqueda básica por título
- [ ] Drag & drop para cambiar fechas
- [ ] Dark mode toggle
- [ ] Exportar tareas a PDF/CSV

---

## 🚫 **NO HACER (Scope Creep)**
- ❌ Subtareas
- ❌ Categorías/proyectos
- ❌ Múltiples usuarios
- ❌ Notificaciones push
- ❌ Integración con calendarios externos
- ❌ Analytics/reportes
- ❌ PWA completa

---

## 📝 **DAILY CHECKLIST**

### **Lunes**: Core CRUD
- [ ] Modal edición funcionando
- [ ] Confirmación eliminación

### **Martes**: UX Básica  
- [ ] Toasts implementados
- [ ] Filtros funcionando

### **Miércoles**: Visual Polish
- [ ] Animaciones suaves
- [ ] Estados de carga

### **Jueves**: Mobile Ready
- [ ] Responsive completo
- [ ] Touch friendly

### **Viernes**: Final Polish
- [ ] Validaciones completas
- [ ] Shortcuts de teclado

### **Sábado**: Testing
- [ ] Todas las funciones probadas
- [ ] Bugs corregidos

### **Domingo**: Deploy
- [ ] Build funcionando
- [ ] App en producción

---

## 🎯 **CRITERIOS DE ÉXITO**
1. ✅ Usuario puede **crear, editar, eliminar** tareas
2. ✅ Usuario puede **asignar fecha, hora, prioridad**
3. ✅ Usuario puede **ver tareas en calendario**
4. ✅ Usuario puede **filtrar tareas básicamente**
5. ✅ App **funciona en móvil y desktop**
6. ✅ App **está desplegada y accesible**

---

**🚀 Próximo paso**: Implementar modal de edición reutilizando el componente actual.