-- =====================================================
-- LIMPIAR FUNCIONES EXISTENTES PRIMERO
-- =====================================================

-- Eliminar funciones existentes
DROP FUNCTION IF EXISTS motivbot_get_tasks;
DROP FUNCTION IF EXISTS motivbot_create_task;
DROP FUNCTION IF EXISTS motivbot_update_task;
DROP FUNCTION IF EXISTS motivbot_delete_task;
DROP FUNCTION IF EXISTS motivbot_get_conversations;
DROP FUNCTION IF EXISTS motivbot_create_conversation;
DROP FUNCTION IF EXISTS motivbot_get_dashboard;
DROP FUNCTION IF EXISTS motivbot_search_tasks;

-- =====================================================
-- MOTIVBOT RPC FUNCTIONS - VERSIÓN COMPLETA PARA GPT ACTIONS
-- =====================================================

-- 1. OBTENER TAREAS (COMPLETO)
CREATE FUNCTION motivbot_get_tasks(
    p_status TEXT DEFAULT NULL,
    p_priority TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    IF p_status IS NOT NULL AND p_priority IS NOT NULL THEN
        SELECT json_agg(task_json)
        INTO result
        FROM (
            SELECT json_build_object(
                'id', id,
                'title', title,
                'description', description,
                'status', status,
                'priority', priority,
                'due_date', due_date,
                'due_time', due_time,
                'created_at', created_at,
                'updated_at', updated_at
            ) as task_json
            FROM public.Task 
            WHERE status = p_status::task_status 
              AND priority = p_priority
            ORDER BY created_at DESC
            LIMIT p_limit
        ) tasks;
    ELSIF p_status IS NOT NULL THEN
        SELECT json_agg(task_json)
        INTO result
        FROM (
            SELECT json_build_object(
                'id', id,
                'title', title,
                'description', description,
                'status', status,
                'priority', priority,
                'due_date', due_date,
                'due_time', due_time,
                'created_at', created_at,
                'updated_at', updated_at
            ) as task_json
            FROM public.Task 
            WHERE status = p_status::task_status
            ORDER BY created_at DESC
            LIMIT p_limit
        ) tasks;
    ELSIF p_priority IS NOT NULL THEN
        SELECT json_agg(task_json)
        INTO result
        FROM (
            SELECT json_build_object(
                'id', id,
                'title', title,
                'description', description,
                'status', status,
                'priority', priority,
                'due_date', due_date,
                'due_time', due_time,
                'created_at', created_at,
                'updated_at', updated_at
            ) as task_json
            FROM public.Task 
            WHERE priority = p_priority
            ORDER BY created_at DESC
            LIMIT p_limit
        ) tasks;
    ELSE
        SELECT json_agg(task_json)
        INTO result
        FROM (
            SELECT json_build_object(
                'id', id,
                'title', title,
                'description', description,
                'status', status,
                'priority', priority,
                'due_date', due_date,
                'due_time', due_time,
                'created_at', created_at,
                'updated_at', updated_at
            ) as task_json
            FROM public.Task 
            ORDER BY created_at DESC
            LIMIT p_limit
        ) tasks;
    END IF;
    
    RETURN COALESCE(result, '[]'::json);
END;
$$;

-- 2. CREAR TAREA (COMPLETO)
CREATE FUNCTION motivbot_create_task(
    p_title TEXT,
    p_description TEXT DEFAULT NULL,
    p_priority TEXT DEFAULT 'normal',
    p_due_date DATE DEFAULT NULL,
    p_due_time TIME DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_task_id BIGINT;
    result JSON;
BEGIN
    -- Validar título
    IF p_title IS NULL OR trim(p_title) = '' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Title is required'
        );
    END IF;
    
    -- Validar prioridad
    IF p_priority NOT IN ('low', 'normal', 'medium', 'high') THEN
        p_priority := 'normal';
    END IF;
    
    INSERT INTO public.Task (title, description, priority, due_date, due_time) 
    VALUES (
        trim(p_title), 
        NULLIF(trim(p_description), ''),
        p_priority,
        p_due_date,
        p_due_time
    ) 
    RETURNING id INTO new_task_id;
    
    SELECT json_build_object(
        'success', true,
        'id', new_task_id,
        'message', 'Task created successfully'
    ) INTO result;
    
    RETURN result;
END;
$$;

-- 3. ACTUALIZAR TAREA (COMPLETO)
CREATE FUNCTION motivbot_update_task(
    p_task_id BIGINT,
    p_title TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_priority TEXT DEFAULT NULL,
    p_due_date DATE DEFAULT NULL,
    p_due_time TIME DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Verificar que la tarea existe
    IF NOT EXISTS (SELECT 1 FROM public.Task WHERE id = p_task_id) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Task not found'
        );
    END IF;
    
    -- Actualizar campos (solo los que no son NULL)
    UPDATE public.Task SET
        title = CASE 
            WHEN p_title IS NOT NULL AND trim(p_title) != '' THEN trim(p_title) 
            ELSE title 
        END,
        description = CASE 
            WHEN p_description IS NOT NULL THEN NULLIF(trim(p_description), '') 
            ELSE description 
        END,
        status = CASE 
            WHEN p_status IS NOT NULL AND p_status IN ('pending', 'completed') THEN p_status::task_status 
            ELSE status 
        END,
        priority = CASE 
            WHEN p_priority IS NOT NULL AND p_priority IN ('low', 'normal', 'medium', 'high') THEN p_priority 
            ELSE priority 
        END,
        due_date = CASE 
            WHEN p_due_date IS NOT NULL THEN p_due_date 
            ELSE due_date 
        END,
        due_time = CASE 
            WHEN p_due_time IS NOT NULL THEN p_due_time 
            ELSE due_time 
        END
    WHERE id = p_task_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Task updated successfully'
    );
END;
$$;

-- 4. ELIMINAR TAREA
CREATE FUNCTION motivbot_delete_task(
    p_task_id BIGINT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    DELETE FROM public.Task WHERE id = p_task_id;
    
    IF FOUND THEN
        SELECT json_build_object(
            'success', true,
            'message', 'Task deleted successfully'
        ) INTO result;
    ELSE
        SELECT json_build_object(
            'success', false,
            'message', 'Task not found'
        ) INTO result;
    END IF;
    
    RETURN result;
END;
$$;

-- 5. OBTENER CONVERSACIONES (COMPLETO)
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
BEGIN
    IF p_task_id IS NOT NULL AND p_role IS NOT NULL THEN
        SELECT json_agg(conv_json)
        INTO result
        FROM (
            SELECT json_build_object(
                'id', id,
                'task_id', task_id,
                'role', role,
                'message', message,
                'user_is_grateful', user_is_grateful,
                'user_is_useful', user_is_useful,
                'assistant_is_useful', assistant_is_useful,
                'assistant_is_precise', assistant_is_precise,
                'assistant_is_grateful', assistant_is_grateful,
                'tokens_used', tokens_used,
                'model_used', model_used,
                'response_time_ms', response_time_ms,
                'created_at', created_at
            ) as conv_json
            FROM public.Conversation 
            WHERE task_id = p_task_id AND role = p_role::conversation_role
            ORDER BY created_at ASC
            LIMIT p_limit
        ) conversations;
    ELSIF p_task_id IS NOT NULL THEN
        SELECT json_agg(conv_json)
        INTO result
        FROM (
            SELECT json_build_object(
                'id', id,
                'task_id', task_id,
                'role', role,
                'message', message,
                'user_is_grateful', user_is_grateful,
                'user_is_useful', user_is_useful,
                'assistant_is_useful', assistant_is_useful,
                'assistant_is_precise', assistant_is_precise,
                'assistant_is_grateful', assistant_is_grateful,
                'tokens_used', tokens_used,
                'model_used', model_used,
                'response_time_ms', response_time_ms,
                'created_at', created_at
            ) as conv_json
            FROM public.Conversation 
            WHERE task_id = p_task_id
            ORDER BY created_at ASC
            LIMIT p_limit
        ) conversations;
    ELSE
        SELECT json_agg(conv_json)
        INTO result
        FROM (
            SELECT json_build_object(
                'id', id,
                'task_id', task_id,
                'role', role,
                'message', message,
                'user_is_grateful', user_is_grateful,
                'user_is_useful', user_is_useful,
                'assistant_is_useful', assistant_is_useful,
                'assistant_is_precise', assistant_is_precise,
                'assistant_is_grateful', assistant_is_grateful,
                'tokens_used', tokens_used,
                'model_used', model_used,
                'response_time_ms', response_time_ms,
                'created_at', created_at
            ) as conv_json
            FROM public.Conversation 
            ORDER BY created_at DESC
            LIMIT p_limit
        ) conversations;
    END IF;
    
    RETURN COALESCE(result, '[]'::json);
END;
$$;

-- 6. CREAR CONVERSACIÓN (COMPLETO)
CREATE FUNCTION motivbot_create_conversation(
    p_task_id BIGINT,
    p_role TEXT,
    p_message TEXT,
    p_model_used TEXT DEFAULT 'gpt-4',
    p_tokens_used INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_conv_id BIGINT;
    result JSON;
BEGIN
    -- Validar parámetros básicos
    IF p_task_id IS NULL OR p_role IS NULL OR p_message IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Task ID, role and message are required'
        );
    END IF;
    
    IF p_role NOT IN ('user', 'assistant') THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Role must be user or assistant'
        );
    END IF;
    
    -- Verificar que la tarea existe
    IF NOT EXISTS (SELECT 1 FROM public.Task WHERE id = p_task_id) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Task not found'
        );
    END IF;
    
    INSERT INTO public.Conversation (task_id, role, message, model_used, tokens_used) 
    VALUES (
        p_task_id, 
        p_role::conversation_role, 
        trim(p_message),
        p_model_used,
        p_tokens_used
    ) 
    RETURNING id INTO new_conv_id;
    
    SELECT json_build_object(
        'success', true,
        'id', new_conv_id,
        'message', 'Conversation created successfully'
    ) INTO result;
    
    RETURN result;
END;
$$;

-- 7. ACTUALIZAR FEEDBACK DE CONVERSACIÓN
CREATE FUNCTION motivbot_update_conversation_feedback(
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
    result JSON;
BEGIN
    -- Verificar que la conversación existe
    IF NOT EXISTS (SELECT 1 FROM public.Conversation WHERE id = p_conversation_id) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Conversation not found'
        );
    END IF;
    
    -- Actualizar feedback
    UPDATE public.Conversation SET
        user_is_grateful = COALESCE(p_user_is_grateful, user_is_grateful),
        user_is_useful = COALESCE(p_user_is_useful, user_is_useful),
        assistant_is_useful = COALESCE(p_assistant_is_useful, assistant_is_useful),
        assistant_is_precise = COALESCE(p_assistant_is_precise, assistant_is_precise),
        assistant_is_grateful = COALESCE(p_assistant_is_grateful, assistant_is_grateful)
    WHERE id = p_conversation_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Feedback updated successfully'
    );
END;
$$;

-- 8. DASHBOARD COMPLETO
CREATE FUNCTION motivbot_get_dashboard()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    total_tasks INTEGER;
    pending_tasks INTEGER;
    completed_tasks INTEGER;
    high_priority_tasks INTEGER;
    overdue_tasks INTEGER;
    total_conversations INTEGER;
    user_messages INTEGER;
    assistant_messages INTEGER;
    total_tokens INTEGER;
    grateful_responses INTEGER;
BEGIN
    -- Estadísticas de tareas
    SELECT COUNT(*) INTO total_tasks FROM public.Task;
    SELECT COUNT(*) INTO pending_tasks FROM public.Task WHERE status = 'pending';
    SELECT COUNT(*) INTO completed_tasks FROM public.Task WHERE status = 'completed';
    SELECT COUNT(*) INTO high_priority_tasks FROM public.Task WHERE priority = 'high';
    SELECT COUNT(*) INTO overdue_tasks FROM public.Task WHERE due_date < CURRENT_DATE AND status = 'pending';
    
    -- Estadísticas de conversaciones
    SELECT COUNT(*) INTO total_conversations FROM public.Conversation;
    SELECT COUNT(*) INTO user_messages FROM public.Conversation WHERE role = 'user';
    SELECT COUNT(*) INTO assistant_messages FROM public.Conversation WHERE role = 'assistant';
    SELECT COALESCE(SUM(tokens_used), 0) INTO total_tokens FROM public.Conversation;
    SELECT COUNT(*) INTO grateful_responses FROM public.Conversation WHERE user_is_grateful = true;
    
    SELECT json_build_object(
        'tasks', json_build_object(
            'total', total_tasks,
            'pending', pending_tasks,
            'completed', completed_tasks,
            'high_priority', high_priority_tasks,
            'overdue', overdue_tasks
        ),
        'conversations', json_build_object(
            'total', total_conversations,
            'user_messages', user_messages,
            'assistant_messages', assistant_messages,
            'total_tokens', total_tokens,
            'grateful_responses', grateful_responses
        ),
        'completion_rate', CASE 
            WHEN total_tasks > 0 THEN ROUND((completed_tasks * 100.0 / total_tasks), 2)
            ELSE 0 
        END
    ) INTO result;
    
    RETURN result;
END;
$$;

-- 9. BUSCAR TAREAS (AVANZADO)
CREATE FUNCTION motivbot_search_tasks(
    p_search TEXT,
    p_status TEXT DEFAULT NULL,
    p_priority TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    where_conditions TEXT := '';
BEGIN
    IF p_search IS NULL OR trim(p_search) = '' THEN
        RETURN '[]'::json;
    END IF;
    
    -- Construir condiciones WHERE
    where_conditions := format('(title ILIKE %L OR description ILIKE %L)', 
                              '%' || trim(p_search) || '%', 
                              '%' || trim(p_search) || '%');
    
    IF p_status IS NOT NULL AND p_status IN ('pending', 'completed') THEN
        where_conditions := where_conditions || format(' AND status = %L::task_status', p_status);
    END IF;
    
    IF p_priority IS NOT NULL AND p_priority IN ('low', 'normal', 'medium', 'high') THEN
        where_conditions := where_conditions || format(' AND priority = %L', p_priority);
    END IF;
    
    EXECUTE format('
        SELECT json_agg(
            json_build_object(
                ''id'', id,
                ''title'', title,
                ''description'', description,
                ''status'', status,
                ''priority'', priority,
                ''due_date'', due_date,
                ''due_time'', due_time,
                ''created_at'', created_at
            )
        )
        FROM public.Task 
        WHERE %s
        ORDER BY 
            CASE priority 
                WHEN ''high'' THEN 1 
                WHEN ''medium'' THEN 2 
                WHEN ''normal'' THEN 3 
                WHEN ''low'' THEN 4 
            END,
            created_at DESC
        LIMIT 20', where_conditions) INTO result;
    
    RETURN COALESCE(result, '[]'::json);
END;
$$;

-- PERMISOS
GRANT EXECUTE ON FUNCTION motivbot_get_tasks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_create_task TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_update_task TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_delete_task TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_get_conversations TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_create_conversation TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_update_conversation_feedback TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_get_dashboard TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_search_tasks TO anon, authenticated;