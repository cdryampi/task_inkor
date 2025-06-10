export default async function handler(req, res) {
  try {
    // Test de conexión a Supabase
    const testUrl = `${process.env.SUPABASE_URL}/rpc/hello_world`;
    if (!process.env.SUPABASE_URL || !process.env.SUPABASE_API_KEY) {
      return res.status(500).json({
        proxy_status: 'error',
        error: 'Supabase URL or API Key is not set in environment variables.',
        timestamp: new Date().toISOString()
      });
    }

    const response = await fetch(testUrl, {
      headers: {
        'apikey': process.env.SUPABASE_API_KEY,
        'Content-Type': 'application/json'
      }
    });

    const data = await response.text();

    res.status(200).json({
      proxy_status: 'working',
      supabase_connection: response.ok ? 'success' : 'failed',
      supabase_status: response.status,
      sample_data: data.substring(0, 500),
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    res.status(500).json({
      proxy_status: 'error',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
}
