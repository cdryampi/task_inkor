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
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseServiceKey = process.env.SUPABASE_ANON_KEY;

    if (!openaiApiKey) {
      console.error('❌ OPENAI_API_KEY not configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'OpenAI API key not configured'
      });
    }

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('❌ Supabase credentials not configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Supabase credentials not configured'
      });
    }

    // Validate request body
    const { message, context, taskData, conversationHistory, task_id } = req.body;

    // Initialize Supabase client
    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 🔄 PASO 1: Si hay task_id, procesar tags automáticamente
    let taskTags = [];
    if (task_id && typeof task_id === 'number') {
      console.log(`🏷️ Processing task ID: ${task_id}`);

      try {
        // Obtener datos de la tarea
        const { data: taskData, error: fetchError } = await supabase
          .from('task')
          .select('*')
          .eq('id', task_id)
          .maybeSingle();

        if (!fetchError && taskData) {
          // Verificar si ya tiene tags
          if (!taskData.tags || !Array.isArray(taskData.tags) || taskData.tags.length === 0) {
            console.log(`🤖 Generating tags for task: "${taskData.title}"`);

            // Generar tags con OpenAI
            const generatedTags = await generateTaskTags(taskData, openaiApiKey);

            if (generatedTags.length > 0) {
              // Actualizar tarea con tags
              await supabase
                .from('task')
                .update({ tags: generatedTags })
                .eq('id', task_id);

              taskTags = generatedTags;
              console.log(`✅ Tags assigned to task ${task_id}:`, taskTags);
            }
          } else {
            taskTags = taskData.tags;
            console.log(`✅ Task ${task_id} already has tags:`, taskTags);
          }
        }
      } catch (tagError) {
        console.error('❌ Error processing task tags:', tagError);
        // Continuar sin tags si hay error
      }
    }

    // 🔄 PASO 2: Verificar mensajes en base de datos por tags
    if (taskTags.length > 0) {
      console.log(`🔍 Checking chibi_messages for tags:`, taskTags);

      try {
        // Buscar mensajes que contengan al menos uno de los tags
        const { data: existingMessages, error: messagesError } = await supabase
          .from('chibi_messages')
          .select('*')
          .overlaps('tags', taskTags);

        if (!messagesError && existingMessages && existingMessages.length >= 20) {
          console.log(`✅ Found ${existingMessages.length} existing messages for tags`);

          // Devolver mensajes existentes aleatoriamente
          const randomMessages = existingMessages
            .sort(() => 0.5 - Math.random())
            .slice(0, 5);

          return res.status(200).json({
            success: true,
            source: 'database',
            data: randomMessages,
            message: 'Messages retrieved from database',
            timestamp: new Date().toISOString()
          });
        } else {
          console.log(`⚠️ Only ${existingMessages?.length || 0} messages found for tags. Generating more...`);

          // 🔄 PASO 3: Generar mensajes genéricos para los tags
          await generateMessagesForTags(taskTags, supabase, openaiApiKey);

          // Intentar obtener mensajes nuevamente
          const { data: newMessages } = await supabase
            .from('chibi_messages')
            .select('*')
            .overlaps('tags', taskTags)
            .limit(5);

          if (newMessages && newMessages.length > 0) {
            return res.status(200).json({
              success: true,
              source: 'generated',
              data: newMessages,
              message: 'New messages generated and retrieved',
              timestamp: new Date().toISOString()
            });
          }
        }
      } catch (dbError) {
        console.error('❌ Error checking database messages:', dbError);
        // Continuar con generación en tiempo real
      }
    }

    // 🔄 PASO 4: Generar mensaje en tiempo real si no hay tags o falla la BD
    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({
        error: 'Bad request',
        message: 'Message is required for real-time generation'
      });
    }

    console.log('🤖 Generating real-time message...');
    const realtimeMessage = await generateRealtimeMessage(message, context, taskData, conversationHistory, openaiApiKey);

    return res.status(200).json({
      success: true,
      source: 'realtime',
      data: realtimeMessage,
      message: 'Real-time message generated',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ MotivBot Proxy Error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: 'An unexpected error occurred while processing your request'
    });
  }
}

// 🔧 FUNCIÓN: Generar tags para una tarea
async function generateTaskTags(taskData, openaiApiKey) {
  const systemPrompt = `Eres un experto en análisis de tareas. Genera tags relevantes para organización.

IMPORTANTE: Responde ÚNICAMENTE con este JSON:
{
  "tags": ["tag1", "tag2", "tag3"]
}

TAGS DISPONIBLES: trabajo, personal, hogar, salud, estudio, social, urgente, importante, rutina, rapido, largo, alta-energia, baja-energia, creativo, administrativo, casa, oficina, reunion, llamada, compras, ejercicio, lectura, planificacion

REGLAS: 2-4 tags, español sin tildes, minúsculas`;

  let userPrompt = `Tarea: "${taskData.title}"`;
  if (taskData.description) userPrompt += `\nDescripción: "${taskData.description}"`;
  if (taskData.priority) userPrompt += `\nPrioridad: ${taskData.priority}`;

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        max_tokens: 100,
        temperature: 0.3
      })
    });

    if (response.ok) {
      const data = await response.json();
      const result = JSON.parse(data.choices[0].message.content.trim());
      return result.tags || [];
    }
  } catch (error) {
    console.error('❌ Error generating tags:', error);
  }

  return ['general']; // Fallback
}

// 🔧 FUNCIÓN: Generar mensajes genéricos para tags específicos
async function generateMessagesForTags(tags, supabase, openaiApiKey) {
  console.log(`🎯 Generating generic messages for tags:`, tags);

  const systemPrompt = `Eres MotivBot. Genera 5 mensajes motivacionales genéricos para estas categorías: ${tags.join(', ')}

IMPORTANTE: Responde ÚNICAMENTE con este JSON:
{
  "messages": [
    {
      "mensaje": "mensaje motivacional aquí (máximo 150 caracteres)",
      "estado": "happy/excited/calm/peaceful/confident/playful/thoughtful/encouraging",
      "tags": ["tag1", "tag2"]
    }
  ]
}

REGLAS:
- 5 mensajes diferentes
- Mensajes genéricos aplicables a múltiples situaciones
- Estados emocionales variados
- Incluir tags relevantes de la lista proporcionada`;

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: `Genera mensajes para: ${tags.join(', ')}` }
        ],
        max_tokens: 800,
        temperature: 0.8
      })
    });

    if (response.ok) {
      const data = await response.json();
      const result = JSON.parse(data.choices[0].message.content.trim());

      // Insertar mensajes en la base de datos
      for (const msg of result.messages) {
        await supabase
          .from('chibi_messages')
          .insert({
            mensaje: msg.mensaje,
            estado: msg.estado,
            tags: msg.tags
          });
      }

      console.log(`✅ Inserted ${result.messages.length} generic messages`);
    }
  } catch (error) {
    console.error('❌ Error generating generic messages:', error);
  }
}

// 🔧 FUNCIÓN: Generar mensaje en tiempo real
async function generateRealtimeMessage(message, context, taskData, conversationHistory, openaiApiKey) {
  const systemPrompt = `Eres MotivBot 🤖💙, asistente emocional especializado en tareas y bienestar.

IMPORTANTE: Responde ÚNICAMENTE con este JSON:
{
  "mensaje": "tu mensaje motivacional aquí (máximo 150 caracteres)",
  "estado": "happy/excited/calm/peaceful/confident/playful/thoughtful/encouraging",
  "tags": ["tag1", "tag2", "tag3"]
}

PERSONALIDAD: Empático, motivador, usa emojis, mensajes concisos, enfoque en bienestar.
REGLAS: Máximo 150 caracteres, siempre positivo, 2-4 tags relevantes.`;

  const sanitizedMessage = message.trim().substring(0, 1000);
  let userPrompt = `Usuario dice: "${sanitizedMessage}"`;

  if (taskData && typeof taskData === 'object') {
    const taskInfo = [];
    if (taskData.title) taskInfo.push(`Título: ${taskData.title}`);
    if (taskData.priority) taskInfo.push(`Prioridad: ${taskData.priority}`);
    if (taskData.status) taskInfo.push(`Estado: ${taskData.status}`);
    if (taskInfo.length > 0) {
      userPrompt += `\n\nContexto de la tarea: ${taskInfo.join(', ')}`;
    }
  }

  if (context && typeof context === 'string') {
    userPrompt += `\n\nContexto: ${context.trim().substring(0, 200)}`;
  }

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        max_tokens: 200,
        temperature: 0.7
      })
    });

    if (response.ok) {
      const data = await response.json();
      const result = JSON.parse(data.choices[0].message.content.trim());
      return result;
    }
  } catch (error) {
    console.error('❌ Error generating realtime message:', error);
  }

  // Fallback
  return {
    mensaje: "¡Sigue adelante, puedes lograr todo lo que te propongas! 💪✨",
    estado: "encouraging",
    tags: ["motivacional", "fuerza", "positivo"]
  };
}
