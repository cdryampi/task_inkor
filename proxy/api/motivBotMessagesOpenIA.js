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
    let currentTaskData = null;

    if (task_id && typeof task_id === 'number') {
      console.log(`🏷️ Processing task ID: ${task_id}`);

      try {
        // Obtener datos de la tarea
        const { data: fetchedTaskData, error: fetchError } = await supabase
          .from('task')
          .select('*')
          .eq('id', task_id)
          .maybeSingle();

        if (!fetchError && fetchedTaskData) {
          currentTaskData = fetchedTaskData;

          // Verificar si ya tiene tags
          if (!fetchedTaskData.tags || !Array.isArray(fetchedTaskData.tags) || fetchedTaskData.tags.length === 0) {
            console.log(`🤖 Generating tags for task: "${fetchedTaskData.title}"`);

            // Generar tags con OpenAI
            const generatedTags = await generateTaskTags(fetchedTaskData, openaiApiKey);

            if (generatedTags.length > 0) {
              // Actualizar tarea con tags
              await supabase
                .from('task')
                .update({ tags: generatedTags })
                .eq('id', task_id);

              taskTags = generatedTags;
              currentTaskData.tags = generatedTags; // Actualizar datos locales
              console.log(`✅ Tags assigned to task ${task_id}:`, taskTags);
            }
          } else {
            taskTags = fetchedTaskData.tags;
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

        if (!messagesError && existingMessages && existingMessages.length >= 5) {
          console.log(`✅ Found ${existingMessages.length} existing messages for tags`);

          // Devolver mensajes existentes aleatoriamente
          const randomMessages = existingMessages
            .sort(() => 0.5 - Math.random())
            .slice(0, 5);

          // Seleccionar uno aleatorio para mostrar
          const selectedMessage = randomMessages[0];

          return res.status(200).json({
            success: true,
            source: 'database',
            data: {
              mensaje: selectedMessage.mensaje,
              estado: selectedMessage.estado,
              tags: selectedMessage.tags || taskTags
            },
            all_messages: randomMessages, // Para debugging
            message: 'Message retrieved from database',
            timestamp: new Date().toISOString()
          });
        } else {
          console.log(`⚠️ Only ${existingMessages?.length || 0} messages found for tags. Generating more...`);

          // 🔄 PASO 3: Generar mensajes genéricos para los tags y devolverlos
          const generatedMessages = await generateMessagesForTags(taskTags, supabase, openaiApiKey);

          if (generatedMessages && generatedMessages.length > 0) {
            // Devolver uno de los mensajes generados
            const selectedMessage = generatedMessages[0];

            return res.status(200).json({
              success: true,
              source: 'generated',
              data: {
                mensaje: selectedMessage.mensaje,
                estado: selectedMessage.estado,
                tags: selectedMessage.tags || taskTags
              },
              all_generated: generatedMessages, // Para debugging
              message: 'New messages generated and one selected',
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
      // Si no hay mensaje pero sí taskData, crear un mensaje contextual
      if (currentTaskData) {
        const contextualMessage = `Dame un mensaje motivacional para mi tarea: "${currentTaskData.title}"`;
        console.log('🤖 Generating contextual message from task data...');
        const realtimeMessage = await generateRealtimeMessage(contextualMessage, context, currentTaskData, conversationHistory, openaiApiKey);

        return res.status(200).json({
          success: true,
          source: 'realtime',
          data: realtimeMessage,
          message: 'Contextual message generated from task',
          timestamp: new Date().toISOString()
        });
      }

      return res.status(400).json({
        error: 'Bad request',
        message: 'Message is required for real-time generation'
      });
    }

    console.log('🤖 Generating real-time message...');
    const realtimeMessage = await generateRealtimeMessage(message, context, currentTaskData || taskData, conversationHistory, openaiApiKey);

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

  // Crear combinaciones de 2 tags máximo para mayor variedad
  const tagCombinations = [];

  // Añadir tags individuales
  tags.forEach(tag => tagCombinations.push([tag]));

  // Añadir combinaciones de 2 tags
  for (let i = 0; i < tags.length; i++) {
    for (let j = i + 1; j < tags.length; j++) {
      tagCombinations.push([tags[i], tags[j]]);
    }
  }

  // Limitar a máximo 3 combinaciones para no generar demasiados
  const selectedCombinations = tagCombinations.slice(0, 3);

  const systemPrompt = `Eres MotivBot 🤖💙. Genera exactamente 5 mensajes motivacionales genéricos.

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
- Exactamente 5 mensajes diferentes
- Mensajes genéricos aplicables a múltiples situaciones
- Estados emocionales variados
- Máximo 150 caracteres por mensaje
- Usar tags de la lista proporcionada
- Mensajes siempre positivos y motivadores`;

  const allGeneratedMessages = [];

  try {
    for (const tagCombo of selectedCombinations) {
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
            { role: 'user', content: `Genera 5 mensajes motivacionales para las categorías: ${tagCombo.join(', ')}` }
          ],
          max_tokens: 800,
          temperature: 0.8
        })
      });

      if (response.ok) {
        const data = await response.json();
        const result = JSON.parse(data.choices[0].message.content.trim());

        if (result.messages && Array.isArray(result.messages)) {
          // Insertar mensajes en la base de datos
          for (const msg of result.messages) {
            try {
              const { data: insertedMessage, error: insertError } = await supabase
                .from('chibi_messages')
                .insert({
                  mensaje: msg.mensaje,
                  estado: msg.estado,
                  tags: msg.tags || tagCombo
                })
                .select()
                .single();

              if (!insertError && insertedMessage) {
                allGeneratedMessages.push(insertedMessage);
              }
            } catch (insertErr) {
              console.error('❌ Error inserting message:', insertErr);
            }
          }
        }
      }

      // Pequeña pausa para no saturar la API
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    console.log(`✅ Generated and inserted ${allGeneratedMessages.length} messages total`);
    return allGeneratedMessages;

  } catch (error) {
    console.error('❌ Error generating generic messages:', error);
    return [];
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

PERSONALIDAD: Empático, motivador, usa emojis ocasionales, mensajes concisos, enfoque en bienestar.
REGLAS: Máximo 150 caracteres, siempre positivo, 2-4 tags relevantes.`;

  const sanitizedMessage = message.trim().substring(0, 1000);
  let userPrompt = `Usuario dice: "${sanitizedMessage}"`;

  if (taskData && typeof taskData === 'object') {
    const taskInfo = [];
    if (taskData.title) taskInfo.push(`Título: ${taskData.title}`);
    if (taskData.priority) taskInfo.push(`Prioridad: ${taskData.priority}`);
    if (taskData.status) taskInfo.push(`Estado: ${taskData.status}`);
    if (taskData.tags) taskInfo.push(`Tags: ${taskData.tags.join(', ')}`);
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
      const contentStr = data.choices[0].message.content.trim();
      const result = JSON.parse(contentStr);

      // Validar que el resultado tenga la estructura correcta
      if (result && result.mensaje && result.estado) {
        return {
          mensaje: result.mensaje.substring(0, 150), // Asegurar límite
          estado: result.estado,
          tags: result.tags || ['motivacional']
        };
      }
    }
  } catch (error) {
    console.error('❌ Error generating realtime message:', error);
  }

  // Fallback mejorado con contexto de tarea si está disponible
  const fallbackTags = taskData?.tags || ['motivacional', 'fuerza', 'positivo'];

  return {
    mensaje: "¡Sigue adelante, puedes lograr todo lo que te propongas! 💪✨",
    estado: "encouraging",
    tags: fallbackTags.slice(0, 3)
  };
}
