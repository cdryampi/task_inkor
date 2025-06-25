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
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY; // Service key para updates

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
    const { task_id } = req.body;

    if (!task_id || typeof task_id !== 'number') {
      return res.status(400).json({
        error: 'Bad request',
        message: 'task_id is required and must be a number'
      });
    }

    console.log(`🏷️ Processing tags for task ID: ${task_id}`);

    // Initialize Supabase client with service key
    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Get task data from Supabase
    const { data: taskData, error: fetchError } = await supabase
      .from('task')
      .select('*')
      .eq('id', task_id)
      .single();

    if (fetchError) {
      console.error('❌ Error fetching task:', fetchError);
      return res.status(404).json({
        error: 'Task not found',
        message: 'Could not retrieve task data'
      });
    }

    // 2. Check if task already has tags
    if (taskData.tags && Array.isArray(taskData.tags) && taskData.tags.length > 0) {
      console.log(`✅ Task ${task_id} already has tags:`, taskData.tags);
      return res.status(200).json({
        success: true,
        message: 'Task already has tags',
        data: {
          task_id: task_id,
          existing_tags: taskData.tags,
          updated: false
        }
      });
    }

    console.log(`🤖 Generating tags for task: "${taskData.title}"`);

    // 3. Build system prompt for tag generation
    const systemPrompt = `Eres un experto en análisis de tareas y productividad. Tu trabajo es asignar tags relevantes a tareas para mejorar su organización y búsqueda.

IMPORTANTE: Debes responder ÚNICAMENTE con un JSON válido en este formato exacto:
{
  "tags": ["tag1", "tag2", "tag3", "tag4"]
}

TIPOS DE TAGS DISPONIBLES:
- Contexto: trabajo, personal, hogar, salud, estudio, social
- Prioridad: urgente, importante, rutina, opcional
- Tiempo: rapido, largo, diario, semanal
- Energía: alta-energia, baja-energia, creativo, administrativo
- Ubicación: casa, oficina, exterior, online
- Categoría: reunion, llamada, compras, ejercicio, lectura, planificacion
- Puedes inventar tags nuevos si son relevantes por ejemplo: python, vuejs, tailwind, css, HTML, javascript, react, nodejs, backend, frontend, fullstack.

REGLAS:
- Máximo 5 tags por tarea
- Mínimo 2 tags por tarea
- Tags en español, sin tildes, minúsculas
- Tags específicos y útiles para filtros
- Considera título, descripción y prioridad
- Responde SOLO con el JSON, sin texto adicional`;

    // 4. Build user prompt with task context
    let userPrompt = `Analiza esta tarea y genera tags apropiados:

Título: "${taskData.title}"`;

    if (taskData.description) {
      userPrompt += `\nDescripción: "${taskData.description}"`;
    }

    if (taskData.priority) {
      userPrompt += `\nPrioridad: ${taskData.priority}`;
    }

    if (taskData.due_date) {
      userPrompt += `\nFecha límite: ${taskData.due_date}`;
    }

    if (taskData.status) {
      userPrompt += `\nEstado: ${taskData.status}`;
    }

    userPrompt += `\n\nGenera tags relevantes en formato JSON.`;

    // 5. Make request to OpenAI
    console.log('🤖 Sending request to OpenAI for tag generation...');

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
        max_tokens: 150,
        temperature: 0.3, // Más determinista para tags
        frequency_penalty: 0.1,
        presence_penalty: 0.1
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

    const aiData = await openaiResponse.json();

    if (!aiData.choices || !aiData.choices[0] || !aiData.choices[0].message) {
      console.error('❌ Invalid OpenAI response structure:', aiData);
      return res.status(500).json({
        error: 'Invalid response',
        message: 'Received invalid response from OpenAI'
      });
    }

    const aiMessage = aiData.choices[0].message.content.trim();

    let generatedTags = [];

    try {
      // 6. Parse JSON response from OpenAI
      const parsedResponse = JSON.parse(aiMessage);

      if (!parsedResponse.tags || !Array.isArray(parsedResponse.tags)) {
        throw new Error('Invalid tags format in OpenAI response');
      }

      generatedTags = parsedResponse.tags.filter(tag =>
        typeof tag === 'string' && tag.length > 0
      ).slice(0, 5); // Máximo 5 tags

      if (generatedTags.length === 0) {
        throw new Error('No valid tags generated');
      }

    } catch (parseError) {
      console.error('❌ Error parsing OpenAI JSON response:', parseError);
      console.error('Raw response:', aiMessage);

      // Fallback tags based on basic analysis
      generatedTags = ['general'];
      if (taskData.title.toLowerCase().includes('trabajo') || taskData.title.toLowerCase().includes('reunión')) {
        generatedTags.push('trabajo');
      }
      if (taskData.priority === 'high') {
        generatedTags.push('urgente');
      }
    }

    console.log(`🏷️ Generated tags for task ${task_id}:`, generatedTags);

    // 7. Update task with generated tags
    const { data: updatedTask, error: updateError } = await supabase
      .from('task')
      .update({ tags: generatedTags })
      .eq('id', task_id)
      .select('*')
      .maybeSingle();

    if (updateError) {
      console.error('❌ Error updating task with tags:', updateError);
      return res.status(500).json({
        error: 'Update failed',
        message: 'Could not update task with generated tags'
      });
    }

    console.log(`✅ Task ${task_id} updated with tags successfully`);

    // 8. Return successful response
    return res.status(200).json({
      success: true,
      message: 'Tags generated and assigned successfully',
      data: {
        task_id: task_id,
        generated_tags: generatedTags,
        updated: true,
        task_data: updatedTask
      },
      usage: aiData.usage || null,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ MotivBot Tag Assignment Error:', error);

    return res.status(500).json({
      error: 'Internal server error',
      message: 'An unexpected error occurred while processing tag assignment'
    });
  }
}
