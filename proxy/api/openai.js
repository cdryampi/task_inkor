export default async function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({
      error: 'Method not allowed',
      message: 'Only POST requests are allowed'
    });
  }

  try {
    // Validate environment variables
    const openaiApiKey = process.env.OPENAI_API_KEY;
    if (!openaiApiKey) {
      console.error('❌ OPENAI_API_KEY not configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'OpenAI API key not configured'
      });
    }

    // Validate request body
    const { message, context, taskData } = req.body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({
        error: 'Bad request',
        message: 'Message is required and must be a non-empty string'
      });
    }

    // Sanitize message (basic security)
    const sanitizedMessage = message.trim().substring(0, 1000);

    // Build system prompt for MotivBot
    const systemPrompt = `Eres MotivBot 🤖💙, un asistente emocional especializado en gestión de tareas y bienestar.

PERSONALIDAD:
- Empático y motivador
- Usa emojis apropiados
- Respuestas concisas pero útiles
- Enfoque en bienestar emocional

CONTEXTO DE LA APP:
- App de tareas llamada "MotivBot"
- Combina productividad con bienestar emocional
- Usuario puede crear, editar, eliminar tareas
- Sistema de prioridades y fechas
- Calendario integrado

REGLAS:
- Respuestas máximo 200 palabras
- Siempre positivo y constructivo
- Si no entiendes algo, pide clarificación
- No dar consejos médicos profesionales
- Enfócate en motivación y organización`;

    // Build user prompt with context
    let userPrompt = sanitizedMessage;

    // Add task context if provided
    if (taskData && typeof taskData === 'object') {
      const taskInfo = [];
      if (taskData.title) taskInfo.push(`Título: ${taskData.title}`);
      if (taskData.description) taskInfo.push(`Descripción: ${taskData.description}`);
      if (taskData.priority) taskInfo.push(`Prioridad: ${taskData.priority}`);
      if (taskData.due_date) taskInfo.push(`Fecha: ${taskData.due_date}`);

      if (taskInfo.length > 0) {
        userPrompt += `\n\nContexto de la tarea:\n${taskInfo.join('\n')}`;
      }
    }

    // Add general context if provided
    if (context && typeof context === 'string') {
      userPrompt += `\n\nContexto adicional: ${context.trim().substring(0, 300)}`;
    }

    console.log('🤖 Sending request to OpenAI...');

    // Make request to OpenAI
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: systemPrompt
          },
          {
            role: 'user',
            content: userPrompt
          }
        ],
        max_tokens: 300,
        temperature: 0.7,
        frequency_penalty: 0.3,
        presence_penalty: 0.3
      })
    });

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.text();
      console.error('❌ OpenAI API Error:', openaiResponse.status, errorData);

      return res.status(openaiResponse.status).json({
        error: 'OpenAI API error',
        message: 'Error communicating with OpenAI service'
      });
    }

    const data = await openaiResponse.json();

    // Validate OpenAI response
    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      console.error('❌ Invalid OpenAI response structure:', data);
      return res.status(500).json({
        error: 'Invalid response',
        message: 'Received invalid response from OpenAI'
      });
    }

    const aiMessage = data.choices[0].message.content.trim();

    console.log('✅ OpenAI response received successfully');

    // Return successful response
    return res.status(200).json({
      success: true,
      message: aiMessage,
      usage: data.usage || null,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ OpenAI Proxy Error:', error);

    return res.status(500).json({
      error: 'Internal server error',
      message: 'An unexpected error occurred while processing your request'
    });
  }
}
