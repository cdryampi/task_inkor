-- 1. Crear el tipo ENUM para roles de conversación
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'conversation_role') THEN
        CREATE TYPE conversation_role AS ENUM ('user', 'assistant');
    END IF;
END$$;

-- 2. Crear la tabla de conversaciones
CREATE TABLE IF NOT EXISTS public.Conversation (
    id BIGSERIAL PRIMARY KEY,
    task_id BIGINT REFERENCES public.Task(id) ON DELETE CASCADE,
    role conversation_role NOT NULL,
    message TEXT NOT NULL,
    
    -- Campos específicos del usuario
    user_is_grateful BOOLEAN DEFAULT false,
    user_is_useful BOOLEAN DEFAULT false,
    
    -- Campos específicos del asistente  
    assistant_is_useful BOOLEAN DEFAULT false,
    assistant_is_precise BOOLEAN DEFAULT false,
    assistant_is_grateful BOOLEAN DEFAULT false,
    
    -- Metadatos de la conversación
    tokens_used INTEGER DEFAULT 0,
    model_used VARCHAR(50) DEFAULT 'gpt-3.5-turbo',
    response_time_ms INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Añadir columna emotional_state si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'conversation' 
        AND column_name = 'emotional_state'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.Conversation 
        ADD COLUMN emotional_state VARCHAR(50) DEFAULT 'neutral';
    END IF;
END$$;

-- 3. Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_conversation_task_id ON public.Conversation(task_id);
CREATE INDEX IF NOT EXISTS idx_conversation_created_at ON public.Conversation(created_at);
CREATE INDEX IF NOT EXISTS idx_conversation_role ON public.Conversation(role);

-- 4. Crear la función para actualizar `updated_at`
DROP FUNCTION IF EXISTS update_conversation_updated_at() CASCADE;
CREATE OR REPLACE FUNCTION update_conversation_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Crear el trigger
DROP TRIGGER IF EXISTS update_conversation_updated_at_trigger ON public.Conversation;
CREATE TRIGGER update_conversation_updated_at_trigger
BEFORE UPDATE ON public.Conversation
FOR EACH ROW
EXECUTE FUNCTION update_conversation_updated_at();

-- 6. Habilitar RLS
ALTER TABLE public.Conversation ENABLE ROW LEVEL SECURITY;

-- 7. Crear políticas de seguridad
-- Permitir SELECT
DROP POLICY IF EXISTS "conversation_select_policy" ON public.Conversation;
CREATE POLICY "conversation_select_policy"
ON public.Conversation
FOR SELECT
TO anon, authenticated
USING (true);

-- Permitir INSERT
DROP POLICY IF EXISTS "conversation_insert_policy" ON public.Conversation;
CREATE POLICY "conversation_insert_policy"
ON public.Conversation
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Permitir UPDATE (para feedback)
DROP POLICY IF EXISTS "conversation_update_policy" ON public.Conversation;
CREATE POLICY "conversation_update_policy"
ON public.Conversation
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- Permitir DELETE
DROP POLICY IF EXISTS "conversation_delete_policy" ON public.Conversation;
CREATE POLICY "conversation_delete_policy"
ON public.Conversation
FOR DELETE
TO anon, authenticated
USING (true);

-- 8. Insertar datos de prueba
INSERT INTO public.Conversation (task_id, role, message, user_is_grateful, user_is_useful) 
VALUES 
(1, 'user', '¿Puedes ayudarme con esta tarea de completar el proyecto Vue?', false, false)
ON CONFLICT DO NOTHING;

INSERT INTO public.Conversation (task_id, role, message, assistant_is_useful, assistant_is_precise, assistant_is_grateful) 
VALUES 
(1, 'assistant', '¡Por supuesto! 😊 Para completar tu proyecto Vue con Supabase, te recomiendo dividirlo en pequeñas tareas: 1) Configurar la conexión, 2) Crear los componentes, 3) Implementar CRUD, 4) Añadir validaciones. ¿Por cuál te gustaría empezar? 💪', true, true, false)
ON CONFLICT DO NOTHING;

INSERT INTO public.Conversation (task_id, role, message, user_is_grateful, user_is_useful) 
VALUES 
(1, 'user', 'Gracias, eso es muy útil. Empezaré por la configuración.', true, true)
ON CONFLICT DO NOTHING;

-- 9. Funciones RPC para GPT Actions y gestión avanzada

-- Función para obtener historial completo de una tarea con contexto
DROP FUNCTION IF EXISTS get_task_conversation_history(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION get_task_conversation_history(
    p_task_id BIGINT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'task_info', (
            SELECT json_build_object(
                'id', t.id,
                'title', t.title,
                'description', t.description,
                'status', t.status,
                'priority', t.priority,
                'due_date', t.due_date,
                'due_time', t.due_time,
                'created_at', t.created_at,
                'updated_at', t.updated_at
            )
            FROM public.Task t WHERE t.id = p_task_id
        ),
        'conversations', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'id', c.id,
                    'role', c.role,
                    'message', c.message,
                    'emotional_state', c.emotional_state,
                    'user_is_grateful', c.user_is_grateful,
                    'user_is_useful', c.user_is_useful,
                    'assistant_is_useful', c.assistant_is_useful,
                    'assistant_is_precise', c.assistant_is_precise,
                    'assistant_is_grateful', c.assistant_is_grateful,
                    'tokens_used', c.tokens_used,
                    'model_used', c.model_used,
                    'response_time_ms', c.response_time_ms,
                    'created_at', c.created_at
                ) ORDER BY c.created_at ASC
            ), '[]'::json)
            FROM public.Conversation c WHERE c.task_id = p_task_id
        ),
        'stats', (
            SELECT json_build_object(
                'total_conversations', COUNT(*),
                'user_messages', COUNT(*) FILTER (WHERE role = 'user'),
                'assistant_messages', COUNT(*) FILTER (WHERE role = 'assistant'),
                'total_tokens', COALESCE(SUM(tokens_used), 0),
                'grateful_responses', COUNT(*) FILTER (WHERE user_is_grateful = true),
                'useful_responses', COUNT(*) FILTER (WHERE user_is_useful = true),
                'emotional_states', json_object_agg(
                    COALESCE(emotional_state, 'neutral'), 
                    COUNT(*) FILTER (WHERE emotional_state IS NOT NULL)
                )
            )
            FROM public.Conversation WHERE task_id = p_task_id
        )
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Función para añadir conversación desde GPT Actions
DROP FUNCTION IF EXISTS add_gpt_conversation(BIGINT, conversation_role, TEXT, VARCHAR(50), VARCHAR(50), VARCHAR(50), INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION add_gpt_conversation(
    p_task_id BIGINT,
    p_role conversation_role,
    p_message TEXT,
    p_emotional_state VARCHAR(50) DEFAULT NULL,
    p_source VARCHAR(50) DEFAULT 'gpt_actions',
    p_model_used VARCHAR(50) DEFAULT 'gpt-4',
    p_tokens_used INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_conversation public.Conversation;
    result JSON;
BEGIN
    -- Validar que la tarea existe
    IF NOT EXISTS (SELECT 1 FROM public.Task WHERE id = p_task_id) THEN
        RAISE EXCEPTION 'Task with ID % does not exist', p_task_id;
    END IF;
    
    -- Validar estado emocional si se proporciona
    IF p_emotional_state IS NOT NULL AND p_emotional_state NOT IN 
       ('happy', 'excited', 'calm', 'focused', 'supportive', 'encouraging', 'thoughtful', 'energetic') THEN
        RAISE EXCEPTION 'Invalid emotional state: %. Valid states are: happy, excited, calm, focused, supportive, encouraging, thoughtful, energetic', p_emotional_state;
    END IF;
    
    -- Insertar nueva conversación
    INSERT INTO public.Conversation (
        task_id, 
        role, 
        message,
        emotional_state,
        model_used, 
        tokens_used,
        response_time_ms
    ) VALUES (
        p_task_id,
        p_role,
        p_message,
        p_emotional_state,
        p_model_used,
        p_tokens_used,
        0
    ) RETURNING * INTO new_conversation;
    
    -- Preparar resultado
    SELECT json_build_object(
        'success', true,
        'conversation', json_build_object(
            'id', new_conversation.id,
            'task_id', new_conversation.task_id,
            'role', new_conversation.role,
            'message', new_conversation.message,
            'emotional_state', new_conversation.emotional_state,
            'created_at', new_conversation.created_at
        ),
        'message', 'Conversation added successfully'
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Función para actualizar feedback de conversación
DROP FUNCTION IF EXISTS update_conversation_feedback(BIGINT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION update_conversation_feedback(
    p_conversation_id BIGINT,
    p_user_is_grateful BOOLEAN DEFAULT NULL,
    p_user_is_useful BOOLEAN DEFAULT NULL,
    p_assistant_is_useful BOOLEAN DEFAULT NULL,
    p_assistant_is_precise BOOLEAN DEFAULT NULL,
    p_assistant_is_grateful BOOLEAN DEFAULT NULL,
    p_emotional_state VARCHAR(50) DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    updated_conversation public.Conversation;
    result JSON;
BEGIN
    -- Validar estado emocional si se proporciona
    IF p_emotional_state IS NOT NULL AND p_emotional_state NOT IN 
       ('happy', 'excited', 'calm', 'focused', 'supportive', 'encouraging', 'thoughtful', 'energetic') THEN
        RAISE EXCEPTION 'Invalid emotional state: %. Valid states are: happy, excited, calm, focused, supportive, encouraging, thoughtful, energetic', p_emotional_state;
    END IF;
    
    -- Actualizar solo los campos que no son NULL
    UPDATE public.Conversation SET
        user_is_grateful = COALESCE(p_user_is_grateful, user_is_grateful),
        user_is_useful = COALESCE(p_user_is_useful, user_is_useful),
        assistant_is_useful = COALESCE(p_assistant_is_useful, assistant_is_useful),
        assistant_is_precise = COALESCE(p_assistant_is_precise, assistant_is_precise),
        assistant_is_grateful = COALESCE(p_assistant_is_grateful, assistant_is_grateful),
        emotional_state = COALESCE(p_emotional_state, emotional_state)
    WHERE id = p_conversation_id
    RETURNING * INTO updated_conversation;
    
    -- Verificar que se actualizó
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Conversation with ID % not found', p_conversation_id;
    END IF;
    
    SELECT json_build_object(
        'success', true,
        'conversation', json_build_object(
            'id', updated_conversation.id,
            'emotional_state', updated_conversation.emotional_state,
            'user_is_grateful', updated_conversation.user_is_grateful,
            'user_is_useful', updated_conversation.user_is_useful,
            'assistant_is_useful', updated_conversation.assistant_is_useful,
            'assistant_is_precise', updated_conversation.assistant_is_precise,
            'assistant_is_grateful', updated_conversation.assistant_is_grateful
        ),
        'message', 'Feedback updated successfully'
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Función para obtener resumen de conversaciones por usuario
DROP FUNCTION IF EXISTS get_conversation_summary(BIGINT[], INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION get_conversation_summary(
    p_task_ids BIGINT[] DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'conversations', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'task_id', c.task_id,
                    'task_title', t.title,
                    'conversation_id', c.id,
                    'role', c.role,
                    'message', LEFT(c.message, 100) || CASE WHEN LENGTH(c.message) > 100 THEN '...' ELSE '' END,
                    'emotional_state', c.emotional_state,
                    'created_at', c.created_at,
                    'feedback_score', (
                        CASE c.role 
                            WHEN 'user' THEN 
                                (CASE WHEN c.user_is_grateful THEN 1 ELSE 0 END) + 
                                (CASE WHEN c.user_is_useful THEN 1 ELSE 0 END)
                            WHEN 'assistant' THEN 
                                (CASE WHEN c.assistant_is_useful THEN 1 ELSE 0 END) + 
                                (CASE WHEN c.assistant_is_precise THEN 1 ELSE 0 END) + 
                                (CASE WHEN c.assistant_is_grateful THEN 1 ELSE 0 END)
                        END
                    )
                ) ORDER BY c.created_at DESC
            ), '[]'::json)
            FROM public.Conversation c
            JOIN public.Task t ON c.task_id = t.id
            WHERE (p_task_ids IS NULL OR c.task_id = ANY(p_task_ids))
            LIMIT p_limit
        ),
        'summary', (
            SELECT json_build_object(
                'total_conversations', COUNT(*),
                'unique_tasks', COUNT(DISTINCT c.task_id),
                'avg_response_time', AVG(c.response_time_ms),
                'total_tokens', SUM(c.tokens_used),
                'emotional_distribution', (
                    SELECT json_object_agg(
                        COALESCE(emotional_state, 'neutral'), 
                        count
                    )
                    FROM (
                        SELECT 
                            COALESCE(emotional_state, 'neutral') as emotional_state,
                            COUNT(*) as count
                        FROM public.Conversation 
                        WHERE (p_task_ids IS NULL OR task_id = ANY(p_task_ids))
                        GROUP BY COALESCE(emotional_state, 'neutral')
                    ) emotion_counts
                ),
                'feedback_stats', json_build_object(
                    'grateful_users', COUNT(*) FILTER (WHERE c.user_is_grateful = true),
                    'useful_for_users', COUNT(*) FILTER (WHERE c.user_is_useful = true),
                    'useful_assistant', COUNT(*) FILTER (WHERE c.assistant_is_useful = true),
                    'precise_assistant', COUNT(*) FILTER (WHERE c.assistant_is_precise = true)
                )
            )
            FROM public.Conversation c
            WHERE (p_task_ids IS NULL OR c.task_id = ANY(p_task_ids))
        )
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Función para obtener estadísticas de estados emocionales
DROP FUNCTION IF EXISTS get_emotional_states_analytics(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION get_emotional_states_analytics(
    p_days_back INTEGER DEFAULT 30
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'period_days', p_days_back,
        'emotional_trends', (
            SELECT json_object_agg(
                COALESCE(emotional_state, 'neutral'),
                json_build_object(
                    'count', count,
                    'percentage', ROUND((count * 100.0 / NULLIF(total_conversations, 0)), 2),
                    'avg_tokens', ROUND(avg_tokens, 0),
                    'recent_messages', (
                        SELECT array_agg(LEFT(message, 50))
                        FROM (
                            SELECT message
                            FROM public.Conversation 
                            WHERE COALESCE(emotional_state, 'neutral') = emotion_analysis.emotional_state
                            AND created_at >= (CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_back)
                            ORDER BY created_at DESC 
                            LIMIT 3
                        ) recent
                    )
                )
            )
            FROM (
                SELECT 
                    COALESCE(c.emotional_state, 'neutral') as emotional_state,
                    COUNT(*) as count,
                    AVG(c.tokens_used) as avg_tokens,
                    COUNT(*) OVER () as total_conversations
                FROM public.Conversation c
                WHERE c.created_at >= (CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_back)
                GROUP BY COALESCE(c.emotional_state, 'neutral')
            ) emotion_analysis
        ),
        'recommendations', (
            SELECT json_build_object(
                'most_used_emotion', most_used,
                'least_used_emotion', least_used,
                'balance_score', ROUND((1.0 - (GREATEST(max_count - min_count, 0) * 1.0 / NULLIF(total_count, 0))) * 100, 2),
                'total_conversations', total_count,
                'unique_emotions', emotion_variety
            )
            FROM (
                SELECT 
                    MAX(count) as max_count,
                    MIN(count) as min_count,
                    SUM(count) as total_count,
                    COUNT(DISTINCT emotional_state) as emotion_variety,
                    (array_agg(emotional_state ORDER BY count DESC))[1] as most_used,
                    (array_agg(emotional_state ORDER BY count ASC))[1] as least_used
                FROM (
                    SELECT 
                        COALESCE(emotional_state, 'neutral') as emotional_state,
                        COUNT(*) as count
                    FROM public.Conversation
                    WHERE created_at >= (CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_back)
                    GROUP BY COALESCE(emotional_state, 'neutral')
                ) emotion_counts
            ) balance_analysis
        )
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Función para obtener conversaciones con filtro de estado emocional
DROP FUNCTION IF EXISTS get_conversations_by_emotion(VARCHAR(50), INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION get_conversations_by_emotion(
    p_emotional_state VARCHAR(50),
    p_limit INTEGER DEFAULT 20
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Validar estado emocional
    IF p_emotional_state NOT IN ('happy', 'excited', 'calm', 'focused', 'supportive', 'encouraging', 'thoughtful', 'energetic', 'neutral') THEN
        RAISE EXCEPTION 'Invalid emotional state: %. Valid states are: happy, excited, calm, focused, supportive, encouraging, thoughtful, energetic, neutral', p_emotional_state;
    END IF;
    
    SELECT json_build_object(
        'emotional_state', p_emotional_state,
        'conversations', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'id', c.id,
                    'task_id', c.task_id,
                    'task_title', t.title,
                    'role', c.role,
                    'message', c.message,
                    'emotional_state', c.emotional_state,
                    'created_at', c.created_at,
                    'tokens_used', c.tokens_used
                ) ORDER BY c.created_at DESC
            ), '[]'::json)
            FROM public.Conversation c
            JOIN public.Task t ON c.task_id = t.id
            WHERE COALESCE(c.emotional_state, 'neutral') = p_emotional_state
            LIMIT p_limit
        ),
        'count', (
            SELECT COUNT(*)
            FROM public.Conversation
            WHERE COALESCE(emotional_state, 'neutral') = p_emotional_state
        )
    ) INTO result;
    
    RETURN result;
END;
$$;

-- CREAR CONVERSACIÓN (FORMATO COMPATIBLE CON TESTS)
DROP FUNCTION IF EXISTS motivbot_create_conversation;
CREATE FUNCTION motivbot_create_conversation(
    p_task_id BIGINT,
    p_role TEXT,
    p_message TEXT,
    p_emotional_state TEXT DEFAULT NULL,
    p_model_used TEXT DEFAULT 'gpt-4',
    p_tokens_used INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_conversation_id BIGINT;
    result JSON;
    insert_query TEXT;
    has_tokens_used BOOLEAN := FALSE;
    has_model_used BOOLEAN := FALSE;
    has_emotional_state BOOLEAN := FALSE;
BEGIN
    -- Verificar que la tarea existe
    IF NOT EXISTS (SELECT 1 FROM public.task WHERE id = p_task_id) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Task not found'
        );
    END IF;
    
    -- Validar parámetros
    IF p_role IS NULL OR p_role NOT IN ('user', 'assistant') THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Role must be user or assistant'
        );
    END IF;
    
    IF p_message IS NULL OR trim(p_message) = '' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Message is required'
        );
    END IF;
    
    -- Verificar qué columnas existen
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'tokens_used'
    ) INTO has_tokens_used;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'model_used'
    ) INTO has_model_used;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'emotional_state'
    ) INTO has_emotional_state;
    
    -- Construir query de inserción dinámicamente con CAST para role
    insert_query := 'INSERT INTO public.conversation (task_id, role, message';
    
    IF has_emotional_state THEN
        insert_query := insert_query || ', emotional_state';
    END IF;
    
    IF has_tokens_used THEN
        insert_query := insert_query || ', tokens_used';
    END IF;
    
    IF has_model_used THEN
        insert_query := insert_query || ', model_used';
    END IF;
    
    insert_query := insert_query || ') VALUES ($1, $2::conversation_role, $3';
    
    IF has_emotional_state THEN
        insert_query := insert_query || ', $4';
    END IF;
    
    IF has_tokens_used THEN
        IF has_emotional_state THEN
            insert_query := insert_query || ', $5';
        ELSE
            insert_query := insert_query || ', $4';    
        END IF;
    END IF;
    
    IF has_model_used THEN
        IF has_emotional_state AND has_tokens_used THEN
            insert_query := insert_query || ', $6';
        ELSIF has_emotional_state OR has_tokens_used THEN
            insert_query := insert_query || ', $5';
        ELSE
            insert_query := insert_query || ', $4';
        END IF;
    END IF;
    
    insert_query := insert_query || ') RETURNING id';
    
    -- Ejecutar inserción según columnas disponibles
    IF has_emotional_state AND has_tokens_used AND has_model_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_emotional_state, p_tokens_used, p_model_used INTO new_conversation_id;
    ELSIF has_emotional_state AND has_tokens_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_emotional_state, p_tokens_used INTO new_conversation_id;
    ELSIF has_emotional_state AND has_model_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_emotional_state, p_model_used INTO new_conversation_id;
    ELSIF has_tokens_used AND has_model_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_tokens_used, p_model_used INTO new_conversation_id;
    ELSIF has_emotional_state THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_emotional_state INTO new_conversation_id;
    ELSIF has_tokens_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_tokens_used INTO new_conversation_id;
    ELSIF has_model_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_model_used INTO new_conversation_id;
    ELSE
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message) INTO new_conversation_id;
    END IF;
    
    -- ✅ FORMATO COMPATIBLE CON TESTS PYTHON
    SELECT json_build_object(
        'success', true,
        'id', new_conversation_id,
        'message', 'Conversation created successfully'
    ) INTO result;
    
    RETURN result;
END;
$$;

-- OBTENER CONVERSACIONES (FORMATO COMPATIBLE CON TESTS)
DROP FUNCTION IF EXISTS motivbot_get_conversations;
CREATE FUNCTION motivbot_get_conversations(
    p_task_id BIGINT DEFAULT NULL,
    p_role TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    has_created_at BOOLEAN := FALSE;
    has_tokens_used BOOLEAN := FALSE;
    has_model_used BOOLEAN := FALSE;
    has_response_time_ms BOOLEAN := FALSE;
    has_emotional_state BOOLEAN := FALSE;
BEGIN
    -- Verificar qué columnas existen en la tabla conversation
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'created_at'
    ) INTO has_created_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'tokens_used'
    ) INTO has_tokens_used;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'model_used'
    ) INTO has_model_used;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'response_time_ms'
    ) INTO has_response_time_ms;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'emotional_state'
    ) INTO has_emotional_state;

    -- ✅ DEVOLVER ARRAY DIRECTO (SIN WRAPPER)
    -- Construir query dinámico
    IF p_task_id IS NOT NULL AND p_role IS NOT NULL THEN
        -- Filtrar por task_id y role
        EXECUTE format('
            SELECT COALESCE(json_agg(conv_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''task_id'', task_id,
                    ''role'', role,
                    ''message'', message,
                    ''user_is_grateful'', user_is_grateful,
                    ''user_is_useful'', user_is_useful,
                    ''assistant_is_useful'', assistant_is_useful,
                    ''assistant_is_precise'', assistant_is_precise,
                    ''assistant_is_grateful'', assistant_is_grateful%s%s%s%s%s
                ) as conv_json
                FROM public.conversation 
                WHERE task_id = $1 AND role = $2::conversation_role
                ORDER BY %s
                LIMIT $3
            ) conversations',
            CASE WHEN has_emotional_state THEN ', ''emotional_state'', emotional_state' ELSE '' END,
            CASE WHEN has_tokens_used THEN ', ''tokens_used'', tokens_used' ELSE '' END,
            CASE WHEN has_model_used THEN ', ''model_used'', model_used' ELSE '' END,
            CASE WHEN has_response_time_ms THEN ', ''response_time_ms'', response_time_ms' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_task_id, p_role, p_limit INTO result;
        
    ELSIF p_task_id IS NOT NULL THEN
        -- Filtrar solo por task_id
        EXECUTE format('
            SELECT COALESCE(json_agg(conv_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''task_id'', task_id,
                    ''role'', role,
                    ''message'', message,
                    ''user_is_grateful'', user_is_grateful,
                    ''user_is_useful'', user_is_useful,
                    ''assistant_is_useful'', assistant_is_useful,
                    ''assistant_is_precise'', assistant_is_precise,
                    ''assistant_is_grateful'', assistant_is_grateful%s%s%s%s%s
                ) as conv_json
                FROM public.conversation 
                WHERE task_id = $1
                ORDER BY %s
                LIMIT $2
            ) conversations',
            CASE WHEN has_emotional_state THEN ', ''emotional_state'', emotional_state' ELSE '' END,
            CASE WHEN has_tokens_used THEN ', ''tokens_used'', tokens_used' ELSE '' END,
            CASE WHEN has_model_used THEN ', ''model_used'', model_used' ELSE '' END,
            CASE WHEN has_response_time_ms THEN ', ''response_time_ms'', response_time_ms' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_task_id, p_limit INTO result;
        
    ELSIF p_role IS NOT NULL THEN
        -- Filtrar solo por role
        EXECUTE format('
            SELECT COALESCE(json_agg(conv_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''task_id'', task_id,
                    ''role'', role,
                    ''message'', message,
                    ''user_is_grateful'', user_is_grateful,
                    ''user_is_useful'', user_is_useful,
                    ''assistant_is_useful'', assistant_is_useful,
                    ''assistant_is_precise'', assistant_is_precise,
                    ''assistant_is_grateful'', assistant_is_grateful%s%s%s%s%s
                ) as conv_json
                FROM public.conversation 
                WHERE role = $1::conversation_role
                ORDER BY %s
                LIMIT $2
            ) conversations',
            CASE WHEN has_emotional_state THEN ', ''emotional_state'', emotional_state' ELSE '' END,
            CASE WHEN has_tokens_used THEN ', ''tokens_used'', tokens_used' ELSE '' END,
            CASE WHEN has_model_used THEN ', ''model_used'', model_used' ELSE '' END,
            CASE WHEN has_response_time_ms THEN ', ''response_time_ms'', response_time_ms' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_role, p_limit INTO result;
        
    ELSE
        -- Sin filtros
        EXECUTE format('
            SELECT COALESCE(json_agg(conv_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''task_id'', task_id,
                    ''role'', role,
                    ''message'', message,
                    ''user_is_grateful'', user_is_grateful,
                    ''user_is_useful'', user_is_useful,
                    ''assistant_is_useful'', assistant_is_useful,
                    ''assistant_is_precise'', assistant_is_precise,
                    ''assistant_is_grateful'', assistant_is_grateful%s%s%s%s%s
                ) as conv_json
                FROM public.conversation 
                ORDER BY %s
                LIMIT $1
            ) conversations',
            CASE WHEN has_emotional_state THEN ', ''emotional_state'', emotional_state' ELSE '' END,
            CASE WHEN has_tokens_used THEN ', ''tokens_used'', tokens_used' ELSE '' END,
            CASE WHEN has_model_used THEN ', ''model_used'', model_used' ELSE '' END,
            CASE WHEN has_response_time_ms THEN ', ''response_time_ms'', response_time_ms' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_limit INTO result;
    END IF;
    
    RETURN result;
END;
$$;

-- Otorgar permisos
GRANT EXECUTE ON FUNCTION motivbot_get_conversations TO anon, authenticated;

-- 10. Otorgar permisos para todas las funciones RPC
GRANT EXECUTE ON FUNCTION get_task_conversation_history(BIGINT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION add_gpt_conversation(BIGINT, conversation_role, TEXT, VARCHAR(50), VARCHAR(50), VARCHAR(50), INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_conversation_feedback(BIGINT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, VARCHAR(50)) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_summary(BIGINT[], INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_emotional_states_analytics(INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_conversations_by_emotion(VARCHAR(50), INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_conversation_updated_at() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_create_conversation(BIGINT, conversation_role, TEXT, VARCHAR(50), VARCHAR(50), INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_get_conversations(BIGINT, conversation_role, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_update_conversation_feedback(BIGINT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_delete_conversation(BIGINT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_create_conversation(BIGINT, TEXT, TEXT, TEXT, TEXT, INTEGER) TO anon, authenticated;