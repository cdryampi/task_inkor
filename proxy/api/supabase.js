export default async function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, apikey, x-client-info, prefer');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    // Validate environment variables
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !supabaseAnonKey) {
      console.error('❌ Supabase credentials not configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Supabase credentials not configured'
      });
    }

    // Extract the Supabase path from the request
    const fullPath = req.url || '';
    const supabasePath = fullPath.replace('/api/supabase/', '').replace('/api/supabase', '');

    // Build the target URL
    const targetUrl = `${supabaseUrl}/rest/v1/${supabasePath}`;

    console.log('🔄 Proxying to Supabase:', {
      method: req.method,
      originalUrl: req.url,
      path: supabasePath,
      targetUrl: targetUrl
    });

    // Prepare headers for Supabase
    const headers = {
      'apikey': supabaseAnonKey,
      'Authorization': `Bearer ${supabaseAnonKey}`,
      'Content-Type': 'application/json',
    };

    // Add prefer header if present (for Supabase operations)
    if (req.headers.prefer) {
      headers.prefer = req.headers.prefer;
    }

    // Add user authorization if present and different from anon key
    if (req.headers.authorization && req.headers.authorization !== `Bearer ${supabaseAnonKey}`) {
      headers.Authorization = req.headers.authorization;
    }

    // Prepare request options
    const requestOptions = {
      method: req.method,
      headers: headers,
    };

    // Add body for POST, PUT, PATCH requests
    if (['POST', 'PUT', 'PATCH'].includes(req.method) && req.body) {
      requestOptions.body = JSON.stringify(req.body);
    }

    // Make request to Supabase
    const supabaseResponse = await fetch(targetUrl, requestOptions);

    // Get response data
    const responseData = await supabaseResponse.text();
    let jsonData;

    try {
      jsonData = JSON.parse(responseData);
    } catch {
      jsonData = responseData;
    }

    // Forward Supabase response headers that are important
    const contentType = supabaseResponse.headers.get('content-type');
    if (contentType) {
      res.setHeader('Content-Type', contentType);
    }

    console.log('✅ Supabase proxy response:', {
      status: supabaseResponse.status,
      hasData: !!jsonData
    });

    // Forward the response with the same status code
    return res.status(supabaseResponse.status).json(jsonData);

  } catch (error) {
    console.error('❌ Supabase Proxy Error:', error);

    return res.status(500).json({
      error: 'Proxy error',
      message: 'An error occurred while proxying the request to Supabase',
      details: error.message
    });
  }
}
