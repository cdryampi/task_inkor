## Servidor proxy para InkorTask Professional - Framework de Gestión Estratégica y Emocional
Este es un servidor proxy que permite la comunicación entre el cliente y el servidor de InkorTask Professional. El proxy se encarga de recibir las peticiones del cliente, procesarlas y enviarlas al servidor correspondiente, así como de recibir las respuestas del servidor y enviarlas de vuelta al cliente.

### Motivos del Proxy
OpenIA Actions requiere el servidor de proxy en vercel para evitar redirecciones de CORS y permitir que el cliente pueda comunicarse con el servidor de InkorTask Professional sin problemas de seguridad.

Asegurar la API de InkorTask Professional para que solo pueda ser accedida a través del proxy, evitando así el acceso directo al servidor y protegiendo la información sensible.

### Recordatorio
Al desplegar el proxy en Vercel, es importante configurar las variables de entorno necesarias para que el proxy funcione correctamente. Estas variables deben incluir la URL del servidor de InkorTask Professional y cualquier otra configuración necesaria para la comunicación entre el proxy y el servidor.
**SUPABASE_URL**, **SUPABASE_ANON_KEY** y **OPENIA_API_KEY** son variables de entorno que deben ser configuradas en Vercel para que el proxy funcione correctamente.