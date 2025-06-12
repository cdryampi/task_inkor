# MotivBot

MotivBot es un pequeño gestor de tareas escrito en **Vue 3** que se apoya en **Supabase** para el almacenamiento y en **OpenAI** para ofrecer recomendaciones motivacionales. Este repositorio contiene tanto la aplicación de cliente como un proxy ligero utilizado para evitar problemas de CORS cuando se accede a Supabase u OpenAI.

## Características

- CRUD de tareas con título, descripción, prioridad y fechas.
- Vista de calendario integrada con [v-calendar](https://vcalendar.io/).
- Registro de conversaciones para cada tarea y asistencia de "MotivBot" mediante IA.
- Proxy opcional para redirigir peticiones a Supabase y a OpenAI.
- Scripts SQL para crear las tablas y funciones utilizadas en Supabase.

## Estructura del proyecto

```
/                Código principal de la aplicación Vue
├─ src/          Componentes, vistas y composables
├─ public/       Recursos estáticos
├─ proxy/        Servidor proxy (deploy en Vercel)
├─ sql/          Scripts para la base de datos
└─ gpt_actions/  Especificación OpenAPI y documentación del bot
```

## Requisitos

- Node.js 18 o superior
- Una instancia de Supabase
- Claves de API para OpenAI si se utiliza el chat motivacional

## Puesta en marcha

1. Instalar las dependencias del proyecto:
   ```bash
   npm install
   ```
2. Copiar el fichero `.env.example` a `.env` y rellenar los valores de `SUPABASE_URL`, `SUPABASE_ANON_KEY` y, opcionalmente, `OPENAI_API_KEY` y `ALLOWED_ORIGINS`.
3. Iniciar el servidor de desarrollo:
   ```bash
   npm run dev
   ```
   La aplicación estará disponible normalmente en `http://localhost:5173`.

### Uso del proxy

El directorio `proxy/` contiene un pequeño servidor preparado para desplegarse en Vercel. Este proxy simplifica las llamadas a Supabase y a OpenAI cuando existen restricciones de CORS o se quiere ocultar la clave pública.

Para ejecutarlo de forma local:

```bash
cd proxy
npm install
npm run dev # necesita Vercel CLI
```

Recuerda establecer las variables de entorno indicadas en `proxy/README.md`.

## Base de datos

Los scripts dentro de `sql/` definen las tablas `Task` y `Conversation`, además de varias funciones RPC para consultas y mantenimiento. Pueden ejecutarse directamente en Supabase para recrear el esquema necesario.

## Documentación adicional

- `gpt_actions/motivbot.yaml` describe la API disponible para integraciones automatizadas.
- `gpt_actions/instrucciones.md` contiene las instrucciones de comportamiento para la IA.
- El archivo `TODO.md` enumera tareas y mejoras pendientes.

---

Este proyecto es experimental y sirve como ejemplo de integración entre Vue, Supabase y servicios de IA. Si encuentras algún problema o quieres proponer mejoras, abre una issue o un pull request.
