export default async function handler(req, res) {
  // Configurar CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, apikey, X-Client-Info');

  // Manejar preflight OPTIONS
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  try {
    // Obtener el path desde query params
    const targetPath = req.query.path || '';

    // Limpiar el path
    const cleanPath = targetPath.startsWith('/') ? targetPath : `/${targetPath}`;

    // Construir la URL completa de Supabase
    const supabaseUrl = `${process.env.SUPABASE_URL}${cleanPath}`;

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

    // Preparar headers
    const headers = {
      'Content-Type': 'application/json',
      'apikey': process.env.SUPABASE_API_KEY,
      'Prefer': 'return=representation'
    };

    // Agregar Authorization si está presente
    if (req.headers.authorization) {
      headers['Authorization'] = req.headers.authorization;
    }

    // Preparar el body para métodos que lo requieren
    let body = undefined;
    if (!['GET', 'HEAD', 'DELETE'].includes(req.method)) {
      if (req.body && typeof req.body === 'string') {
        body = req.body;
      } else if (req.body && typeof req.body === 'object') {
        body = JSON.stringify(req.body);
      }
    }

    // Hacer la petición a Supabase (fetch es global en Node 18+)
    const response = await fetch(finalUrl, {
      method: req.method,
      headers: headers,
      body: body
    });

    // Obtener la respuesta
    const responseText = await response.text();

    // Log para debugging
    console.log(`[PROXY] Response: ${response.status}`);

    // Enviar headers de respuesta
    response.headers.forEach((value, key) => {
      if (key.toLowerCase() !== 'content-encoding') {
        res.setHeader(key, value);
      }
    });

    // Enviar la respuesta
    res.status(response.status);

    // Intentar parsear como JSON
    try {
      const jsonData = JSON.parse(responseText);
      res.json(jsonData);
    } catch {
      res.send(responseText);
    }

  } catch (error) {
    console.error('[PROXY] Error:', error);
    res.status(500).json({
      error: 'Proxy error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
}
