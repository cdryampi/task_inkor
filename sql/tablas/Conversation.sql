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

ALTER TABLE conversation 
ADD COLUMN emotional_state VARCHAR(50) DEFAULT 'neutral';


-- 3. Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_conversation_task_id ON public.Conversation(task_id);
CREATE INDEX IF NOT EXISTS idx_conversation_created_at ON public.Conversation(created_at);
CREATE INDEX IF NOT EXISTS idx_conversation_role ON public.Conversation(role);

-- 4. Crear la función para actualizar `updated_at`
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
(1, 'user', '¿Puedes ayudarme con esta tarea de completar el proyecto Vue?', false, false);

INSERT INTO public.Conversation (task_id, role, message, assistant_is_useful, assistant_is_precise, assistant_is_grateful) 
VALUES 
(1, 'assistant', '¡Por supuesto! 😊 Para completar tu proyecto Vue con Supabase, te recomiendo dividirlo en pequeñas tareas: 1) Configurar la conexión, 2) Crear los componentes, 3) Implementar CRUD, 4) Añadir validaciones. ¿Por cuál te gustaría empezar? 💪', true, true, false);

INSERT INTO public.Conversation (task_id, role, message, user_is_grateful, user_is_useful) 
VALUES 
(1, 'user', 'Gracias, eso es muy útil. Empezaré por la configuración.', true, true);

-- 9. Funciones RPC para GPT Actions y gestión avanzada

-- Función para obtener historial completo de una tarea con contexto
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
                'useful_responses', COUNT(*) FILTER (WHERE user_is_useful = true)
            )
            FROM public.Conversation WHERE task_id = p_task_id
        )
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Función para añadir conversación desde GPT Actions
CREATE OR REPLACE FUNCTION add_gpt_conversation(
    p_task_id BIGINT,
    p_role conversation_role,
    p_message TEXT,
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
    
    -- Insertar nueva conversación
    INSERT INTO public.Conversation (
        task_id, 
        role, 
        message, 
        model_used, 
        tokens_used,
        response_time_ms
    ) VALUES (
        p_task_id,
        p_role,
        p_message,
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
            'created_at', new_conversation.created_at
        ),
        'message', 'Conversation added successfully'
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Función para actualizar feedback de conversación
CREATE OR REPLACE FUNCTION update_conversation_feedback(
    p_conversation_id BIGINT,
    p_user_is_grateful BOOLEAN DEFAULT NULL,
    p_user_is_useful BOOLEAN DEFAULT NULL,
    p_assistant_is_useful BOOLEAN DEFAULT NULL,
    p_assistant_is_precise BOOLEAN DEFAULT NULL,
    p_assistant_is_grateful BOOLEAN DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    updated_conversation public.Conversation;
    result JSON;
BEGIN
    -- Actualizar solo los campos que no son NULL
    UPDATE public.Conversation SET
        user_is_grateful = COALESCE(p_user_is_grateful, user_is_grateful),
        user_is_useful = COALESCE(p_user_is_useful, user_is_useful),
        assistant_is_useful = COALESCE(p_assistant_is_useful, assistant_is_useful),
        assistant_is_precise = COALESCE(p_assistant_is_precise, assistant_is_precise),
        assistant_is_grateful = COALESCE(p_assistant_is_grateful, assistant_is_grateful)
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

-- Función para limpiar conversaciones antiguas
CREATE OR REPLACE FUNCTION cleanup_old_conversations(
    p_days_old INTEGER DEFAULT 30
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
    result JSON;
BEGIN
    -- Eliminar conversaciones más antiguas que p_days_old días
    DELETE FROM public.Conversation 
    WHERE created_at < (CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_old);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    SELECT json_build_object(
        'success', true,
        'deleted_conversations', deleted_count,
        'cutoff_date', (CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_old),
        'message', format('Deleted %s conversations older than %s days', deleted_count, p_days_old)
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Agregar columnas faltantes a la tabla conversation si no existen
ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS response_time_ms INTEGER DEFAULT 0;

-- Verificar que todas las columnas existan
ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS user_is_grateful BOOLEAN DEFAULT NULL;

ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS user_is_useful BOOLEAN DEFAULT NULL;

ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS assistant_is_useful BOOLEAN DEFAULT NULL;

ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS assistant_is_precise BOOLEAN DEFAULT NULL;

ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS assistant_is_grateful BOOLEAN DEFAULT NULL;

ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS tokens_used INTEGER DEFAULT 0;

ALTER TABLE public.conversation 
ADD COLUMN IF NOT EXISTS model_used TEXT DEFAULT 'gpt-4';