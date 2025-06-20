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
    const { message, context, taskData, conversationHistory } = req.body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({
        error: 'Bad request',
        message: 'Message is required and must be a non-empty string'
      });
    }

    // Sanitize message (basic security)
    const sanitizedMessage = message.trim().substring(0, 1000);

    // Build system prompt for MotivBot with JSON response
    const systemPrompt = `Eres MotivBot 🤖💙, un asistente emocional especializado en gestión de tareas y bienestar.

PERSONALIDAD:
- Empático y motivador
- Usa emojis apropiados
- Respuestas concisas pero útiles
- Enfoque en bienestar emocional
- IMPORTANTE: Mantén coherencia con conversaciones anteriores

CONTEXTO DE LA APP:
- App de tareas llamada "MotivBot"
- Combina productividad con bienestar emocional
- Usuario puede crear, editar, eliminar tareas
- Sistema de prioridades y fechas
- Calendario integrado

REGLAS:
- Respuestas máximo 200 palabras
- Siempre positivo y constructivo
- Si hay historial previo, referéncialo cuando sea relevante
- No repitas consejos ya dados anteriormente
- Si no entiendes algo, pide clarificación
- No dar consejos médicos profesionales
- Enfócate en motivación y organización

FORMATO DE RESPUESTA:
Debes responder SIEMPRE en formato JSON válido con esta estructura:
{
  "message": "Tu respuesta motivacional aquí",
  "emotionalState": "estado_emocional",
  "suggestions": ["sugerencia1", "sugerencia2", "sugerencia3"]
}

ESTADOS EMOCIONALES VÁLIDOS:
- "happy" - Feliz/Motivado
- "excited" - Emocionado/Entusiasta
- "calm" - Tranquilo/Relajado
- "focused" - Concentrado/Productivo
- "supportive" - Comprensivo/Apoyo
- "encouraging" - Alentador/Inspirador
- "thoughtful" - Reflexivo/Pensativo
- "energetic" - Enérgico/Activo

IMPORTANTE: Tu respuesta debe ser SOLO el JSON, sin texto adicional antes o después.

${conversationHistory && conversationHistory.length > 0 ?
  `NOTA: Esta conversación tiene historial previo. Mantén coherencia y evita repetir consejos.` :
  `NOTA: Esta es una nueva conversación sin historial previo.`}`;

    // Build user prompt with enhanced context
    let userPrompt = sanitizedMessage;

    // Add conversation history summary if exists
    if (conversationHistory && Array.isArray(conversationHistory) && conversationHistory.length > 0) {
      const recentHistory = conversationHistory.slice(-5); // Últimas 5 para no sobrecargar
      const historyText = recentHistory.map(conv =>
        `${conv.role === 'user' ? 'Usuario' : 'MotivBot'}: ${conv.message.substring(0, 150)}...`
      ).join('\n');

      userPrompt += `\n\n--- Historial reciente de la conversación ---\n${historyText}\n--- Fin del historial ---`;
    }

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

    console.log('🤖 Sending request to OpenAI with history context...');

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
        max_tokens: 400, // Aumentamos para el JSON
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

    // Parse JSON response from AI
    let parsedResponse;
    try {
      parsedResponse = JSON.parse(aiMessage);
    } catch (parseError) {
      console.error('❌ Error parsing AI JSON response:', parseError);
      console.log('Raw AI response:', aiMessage);

      // Fallback response if JSON parsing fails
      parsedResponse = {
        message: aiMessage,
        emotionalState: 'supportive',
        suggestions: ['Mantén una actitud positiva', 'Organiza tus tareas por prioridad', 'Toma descansos regulares']
      };
    }

    // Validate parsed response structure
    if (!parsedResponse.message) {
      parsedResponse.message = 'Lo siento, hubo un problema procesando tu solicitud. ¿Puedes intentarlo de nuevo?';
    }
    if (!parsedResponse.emotionalState) {
      parsedResponse.emotionalState = 'supportive';
    }
    if (!Array.isArray(parsedResponse.suggestions)) {
      parsedResponse.suggestions = [];
    }

    console.log('✅ OpenAI response parsed successfully:', parsedResponse);

    // Return successful response with structured data
    return res.status(200).json({
      success: true,
      message: parsedResponse.message,
      emotionalState: parsedResponse.emotionalState,
      suggestions: parsedResponse.suggestions,
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
