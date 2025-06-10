export default async function handler(req, res) {
  // Configurar CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, apikey, X-Client-Info, prefer');

  // Manejar preflight OPTIONS
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    // Validar variables de entorno
    if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
      console.error('❌ Missing Supabase credentials');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Supabase credentials not configured'
      });
    }

    // Obtener el path desde query params
    const targetPath = req.query.path || '';

    // Validar que hay un path
    if (!targetPath) {
      return res.status(400).json({
        error: 'Bad request',
        message: 'Path parameter is required'
      });
    }

    // Limpiar el path - asegurarse de que comience con /rest/v1/
    let cleanPath = targetPath;
    if (!cleanPath.startsWith('/rest/v1/')) {
      cleanPath = `/rest/v1/${cleanPath.replace(/^\/+/, '')}`;
    }

    // Construir la URL completa de Supabase
    const baseUrl = process.env.SUPABASE_URL.replace(/\/$/, ''); // Remove trailing slash
    const supabaseUrl = `${baseUrl}${cleanPath}`;

    // Construir query string si hay parámetros adicionales
    const queryParams = new URLSearchParams();
    Object.keys(req.query).forEach(key => {
      if (key !== 'path') {
        queryParams.append(key, req.query[key]);
      }
    });

    const finalUrl = queryParams.toString() ?
      `${supabaseUrl}?${queryParams.toString()}` :
      supabaseUrl;

    console.log(`[PROXY] ${req.method} ${finalUrl}`);

    // Preparar headers - USAR SUPABASE_ANON_KEY, no SUPABASE_API_KEY
    const headers = {
      'Content-Type': 'application/json',
      'apikey': process.env.SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${process.env.SUPABASE_ANON_KEY}`
    };

    // Agregar prefer header si está presente
    if (req.headers.prefer) {
      headers['Prefer'] = req.headers.prefer;
    } else {
      headers['Prefer'] = 'return=representation';
    }

    // Sobrescribir Authorization si el cliente envía una diferente (usuario autenticado)
    if (req.headers.authorization && req.headers.authorization !== `Bearer ${process.env.SUPABASE_ANON_KEY}`) {
      headers['Authorization'] = req.headers.authorization;
    }

    // Preparar el body para métodos que lo requieren
    let body = undefined;
    if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
      if (req.body) {
        body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
      }
    }

    // Hacer la petición a Supabase
    const response = await fetch(finalUrl, {
      method: req.method,
      headers: headers,
      body: body
    });

    // Obtener la respuesta
    const responseText = await response.text();

    console.log(`[PROXY] Response: ${response.status}`);

    // Configurar headers de respuesta
    const contentType = response.headers.get('content-type');
    if (contentType) {
      res.setHeader('Content-Type', contentType);
    }

    // Enviar la respuesta con el status code correcto
    res.status(response.status);

    // Intentar parsear como JSON si es aplicable
    if (contentType && contentType.includes('application/json')) {
      try {
        const jsonData = JSON.parse(responseText);
        return res.json(jsonData);
      } catch (parseError) {
        console.warn('[PROXY] Failed to parse JSON response:', parseError);
        return res.send(responseText);
      }
    } else {
      return res.send(responseText);
    }

  } catch (error) {
    console.error('[PROXY] Error:', error);
    return res.status(500).json({
      error: 'Proxy error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
}
