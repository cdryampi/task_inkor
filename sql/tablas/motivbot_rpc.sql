-- =====================================================
-- LIMPIAR FUNCIONES EXISTENTES PRIMERO
-- =====================================================

DROP FUNCTION IF EXISTS motivbot_get_tasks;
DROP FUNCTION IF EXISTS motivbot_create_task;
DROP FUNCTION IF EXISTS motivbot_update_task;
DROP FUNCTION IF EXISTS motivbot_delete_task;
DROP FUNCTION IF EXISTS motivbot_get_conversations;
DROP FUNCTION IF EXISTS motivbot_create_conversation;
DROP FUNCTION IF EXISTS motivbot_update_conversation_feedback;
DROP FUNCTION IF EXISTS motivbot_get_dashboard;
DROP FUNCTION IF EXISTS motivbot_search_tasks;
DROP FUNCTION IF EXISTS motivbot_delete_conversation;

-- =====================================================
-- MOTIVBOT RPC FUNCTIONS - VERSIÓN CORREGIDA
-- =====================================================

-- 1. OBTENER TAREAS (CORREGIDO) - Sin problemas de GROUP BY
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
    has_created_at BOOLEAN := FALSE;
    has_updated_at BOOLEAN := FALSE;
    has_due_date BOOLEAN := FALSE;
    has_due_time BOOLEAN := FALSE;
    has_priority BOOLEAN := FALSE;
BEGIN
    -- Verificar qué columnas existen
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'created_at'
    ) INTO has_created_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'due_date'
    ) INTO has_due_date;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'due_time'
    ) INTO has_due_time;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'priority'
    ) INTO has_priority;

    -- Construir query corregido - Estructura correcta con subquery
    IF p_status IS NOT NULL AND p_priority IS NOT NULL AND has_priority THEN
        -- Filtrar por status y priority
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE status = $1::task_status AND priority = $2
                ORDER BY %s
                LIMIT $3
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_status, p_priority, p_limit INTO result;
        
    ELSIF p_status IS NOT NULL THEN
        -- Filtrar solo por status
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE status = $1::task_status
                ORDER BY %s
                LIMIT $2
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_status, p_limit INTO result;
        
    ELSIF p_priority IS NOT NULL AND has_priority THEN
        -- Filtrar solo por priority
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE priority = $1
                ORDER BY %s
                LIMIT $2
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_priority, p_limit INTO result;
        
    ELSE
        -- Sin filtros
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s
                ) as task_json
                FROM public.task 
                ORDER BY %s
                LIMIT $1
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_limit INTO result;
    END IF;
    
    RETURN result;
END;
$$;

-- 2. CREAR TAREA (MANTENEMOS LA MISMA LÓGICA)
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
    insert_query TEXT;
    has_priority BOOLEAN := FALSE;
    has_due_date BOOLEAN := FALSE;
    has_due_time BOOLEAN := FALSE;
BEGIN
    -- Validar título
    IF p_title IS NULL OR trim(p_title) = '' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Title is required'
        );
    END IF;
    
    -- Verificar qué columnas existen
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'priority'
    ) INTO has_priority;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'due_date'
    ) INTO has_due_date;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'due_time'
    ) INTO has_due_time;
    
    -- Construir query de inserción dinámicamente
    insert_query := 'INSERT INTO public.task (title, description';
    
    IF has_priority THEN
        insert_query := insert_query || ', priority';
    END IF;
    
    IF has_due_date THEN
        insert_query := insert_query || ', due_date';
    END IF;
    
    IF has_due_time THEN
        insert_query := insert_query || ', due_time';
    END IF;
    
    insert_query := insert_query || ') VALUES ($1, $2';
    
    IF has_priority THEN
        insert_query := insert_query || ', $3';
    END IF;
    
    IF has_due_date THEN
        IF has_priority THEN
            insert_query := insert_query || ', $4';
        ELSE
            insert_query := insert_query || ', $3';
        END IF;
    END IF;
    
    IF has_due_time THEN
        IF has_priority AND has_due_date THEN
            insert_query := insert_query || ', $5';
        ELSIF has_priority OR has_due_date THEN
            insert_query := insert_query || ', $4';
        ELSE
            insert_query := insert_query || ', $3';
        END IF;
    END IF;
    
    insert_query := insert_query || ') RETURNING id';
    
    -- Ejecutar inserción según columnas disponibles
    IF has_priority AND has_due_date AND has_due_time THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_priority, p_due_date, p_due_time INTO new_task_id;
    ELSIF has_priority AND has_due_date THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_priority, p_due_date INTO new_task_id;
    ELSIF has_priority AND has_due_time THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_priority, p_due_time INTO new_task_id;
    ELSIF has_priority THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_priority INTO new_task_id;
    ELSIF has_due_date AND has_due_time THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_due_date, p_due_time INTO new_task_id;
    ELSIF has_due_date THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_due_date INTO new_task_id;
    ELSIF has_due_time THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_due_time INTO new_task_id;
    ELSE
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), '') INTO new_task_id;
    END IF;
    
    SELECT json_build_object(
        'success', true,
        'id', new_task_id,
        'message', 'Task created successfully'
    ) INTO result;
    
    RETURN result;
END;
$$;

-- 3. ACTUALIZAR TAREA (DINÁMICO)
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
    update_query TEXT;
    has_priority BOOLEAN := FALSE;
    has_due_date BOOLEAN := FALSE;
    has_due_time BOOLEAN := FALSE;
    has_updated_at BOOLEAN := FALSE;
BEGIN
    -- Verificar que la tarea existe
    IF NOT EXISTS (SELECT 1 FROM public.task WHERE id = p_task_id) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Task not found'
        );
    END IF;
    
    -- Verificar qué columnas existen
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'priority'
    ) INTO has_priority;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'due_date'
    ) INTO has_due_date;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'due_time'
    ) INTO has_due_time;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    -- Construir query de actualización dinámicamente
    update_query := 'UPDATE public.task SET
        title = CASE 
            WHEN $2 IS NOT NULL AND trim($2) != '''' THEN trim($2) 
            ELSE title 
        END,
        description = CASE 
            WHEN $3 IS NOT NULL THEN NULLIF(trim($3), '''') 
            ELSE description 
        END,
        status = CASE 
            WHEN $4 IS NOT NULL THEN $4::task_status 
            ELSE status 
        END';
    
    -- Agregar campos opcionales si existen
    IF has_priority THEN
        update_query := update_query || ',

        priority = CASE 
            WHEN $5 IS NOT NULL AND $5 IN (''low'', ''normal'', ''medium'', ''high'') THEN $5 
            ELSE priority 
        END';
    END IF;
    
    IF has_due_date THEN
        update_query := update_query || ',
        due_date = CASE 
            WHEN $6 IS NOT NULL THEN $6 
            ELSE due_date 
        END';
    END IF;
    
    IF has_due_time THEN
        update_query := update_query || ',
        due_time = CASE 
            WHEN $7 IS NOT NULL THEN $7 
            ELSE due_time 
        END';
    END IF;
    
    IF has_updated_at THEN
        update_query := update_query || ',
        updated_at = NOW()';
    END IF;
    
    update_query := update_query || ' WHERE id = $1';
    
    -- Ejecutar actualización
    EXECUTE update_query USING p_task_id, p_title, p_description, p_status, p_priority, p_due_date, p_due_time;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Task updated successfully'
    );
END;
$$;

-- 4. ELIMINAR TAREA (SIN CAMBIOS)
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
    DELETE FROM public.task WHERE id = p_task_id;
    
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

-- 5. OBTENER CONVERSACIONES
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
                    ''assistant_is_grateful'', assistant_is_grateful%s%s%s%s
                ) as conv_json
                FROM public.conversation 
                WHERE task_id = $1 AND role = $2
                ORDER BY %s
                LIMIT $3
            ) conversations',
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
                    ''assistant_is_grateful'', assistant_is_grateful%s%s%s%s
                ) as conv_json
                FROM public.conversation 
                WHERE task_id = $1
                ORDER BY %s
                LIMIT $2
            ) conversations',
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
                    ''assistant_is_grateful'', assistant_is_grateful%s%s%s%s
                ) as conv_json
                FROM public.conversation 
                WHERE role = $1
                ORDER BY %s
                LIMIT $2
            ) conversations',
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
                    ''assistant_is_grateful'', assistant_is_grateful%s%s%s%s
                ) as conv_json
                FROM public.conversation 
                ORDER BY %s
                LIMIT $1
            ) conversations',
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

-- 6. CREAR CONVERSACIÓN (CORREGIDO)
CREATE OR REPLACE FUNCTION motivbot_create_conversation(
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
    new_conversation_id BIGINT;
    result JSON;
    insert_query TEXT;
    has_tokens_used BOOLEAN := FALSE;
    has_model_used BOOLEAN := FALSE;
    has_response_time_ms BOOLEAN := FALSE;
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
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'response_time_ms'
    ) INTO has_response_time_ms;
    
    -- Construir query de inserción dinámicamente con CAST para role
    insert_query := 'INSERT INTO public.conversation (task_id, role, message';
    
    IF has_tokens_used THEN
        insert_query := insert_query || ', tokens_used';
    END IF;
    
    IF has_model_used THEN
        insert_query := insert_query || ', model_used';
    END IF;
    
    insert_query := insert_query || ') VALUES ($1, $2::conversation_role, $3';
    
    IF has_tokens_used THEN
        insert_query := insert_query || ', $4';
    END IF;
    
    IF has_model_used THEN
        IF has_tokens_used THEN
            insert_query := insert_query || ', $5';
        ELSE
            insert_query := insert_query || ', $4';
        END IF;
    END IF;
    
    insert_query := insert_query || ') RETURNING id';
    
    -- Ejecutar inserción según columnas disponibles
    IF has_tokens_used AND has_model_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_tokens_used, p_model_used INTO new_conversation_id;
    ELSIF has_tokens_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_tokens_used INTO new_conversation_id;
    ELSIF has_model_used THEN
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message), p_model_used INTO new_conversation_id;
    ELSE
        EXECUTE insert_query USING p_task_id, p_role, trim(p_message) INTO new_conversation_id;
    END IF;
    
    SELECT json_build_object(
        'success', true,
        'id', new_conversation_id,
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
    IF NOT EXISTS (SELECT 1 FROM public.conversation WHERE id = p_conversation_id) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Conversation not found'
        );
    END IF;
    
    -- Actualizar feedback
    UPDATE public.conversation SET
        user_is_grateful = CASE 
            WHEN p_user_is_grateful IS NOT NULL THEN p_user_is_grateful 
            ELSE user_is_grateful 
        END,
        user_is_useful = CASE 
            WHEN p_user_is_useful IS NOT NULL THEN p_user_is_useful 
            ELSE user_is_useful 
        END,
        assistant_is_useful = CASE 
            WHEN p_assistant_is_useful IS NOT NULL THEN p_assistant_is_useful 
            ELSE assistant_is_useful 
        END,
        assistant_is_precise = CASE 
            WHEN p_assistant_is_precise IS NOT NULL THEN p_assistant_is_precise 
            ELSE assistant_is_precise 
        END,
        assistant_is_grateful = CASE 
            WHEN p_assistant_is_grateful IS NOT NULL THEN p_assistant_is_grateful 
            ELSE assistant_is_grateful 
        END
    WHERE id = p_conversation_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Conversation feedback updated successfully'
    );
END;
$$;

-- 8. ELIMINAR CONVERSACIÓN
CREATE FUNCTION motivbot_delete_conversation(
    p_conversation_id BIGINT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    DELETE FROM public.conversation WHERE id = p_conversation_id;
    
    IF FOUND THEN
        SELECT json_build_object(
            'success', true,
            'message', 'Conversation deleted successfully'
        ) INTO result;
    ELSE
        SELECT json_build_object(
            'success', false,
            'message', 'Conversation not found'
        ) INTO result;
    END IF;
    
    RETURN result;
END;
$$;

-- 9. BUSCAR TAREAS
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
    has_created_at BOOLEAN := FALSE;
    has_updated_at BOOLEAN := FALSE;
    has_due_date BOOLEAN := FALSE;
    has_due_time BOOLEAN := FALSE;
    has_priority BOOLEAN := FALSE;
BEGIN
    -- Validar parámetro de búsqueda
    IF p_search IS NULL OR trim(p_search) = '' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Search term is required'
        );
    END IF;
    
    -- Verificar qué columnas existen
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'created_at'
    ) INTO has_created_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'due_date'
    ) INTO has_due_date;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'due_time'
    ) INTO has_due_time;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'priority'
    ) INTO has_priority;

    -- Construir query de búsqueda
    IF p_status IS NOT NULL AND p_priority IS NOT NULL AND has_priority THEN
        -- Búsqueda con filtros de status y priority
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE (title ILIKE $1 OR description ILIKE $1) 
                AND status = $2::task_status 
                AND priority = $3
                ORDER BY %s
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING '%' || trim(p_search) || '%', p_status, p_priority INTO result;
        
    ELSIF p_status IS NOT NULL THEN
        -- Búsqueda con filtro de status
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE (title ILIKE $1 OR description ILIKE $1) 
                AND status = $2::task_status
                ORDER BY %s
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING '%' || trim(p_search) || '%', p_status INTO result;
        
    ELSIF p_priority IS NOT NULL AND has_priority THEN
        -- Búsqueda con filtro de priority
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE (title ILIKE $1 OR description ILIKE $1) 
                AND priority = $2
                ORDER BY %s
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING '%' || trim(p_search) || '%', p_priority INTO result;
        
    ELSE
        -- Búsqueda sin filtros adicionales
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE title ILIKE $1 OR description ILIKE $1
                ORDER BY %s
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING '%' || trim(p_search) || '%' INTO result;
    END IF;
    
    RETURN result;
END;
$$;

-- 10. DASHBOARD ANALYTICS
CREATE FUNCTION motivbot_get_dashboard()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    task_stats JSON;
    conversation_stats JSON;
    completion_rate NUMERIC;
    active_tasks INTEGER;
BEGIN
    -- Estadísticas de tareas
    SELECT json_build_object(
        'total', COUNT(*),
        'pending', COUNT(*) FILTER (WHERE status = 'pending'),
        'in_progress', COUNT(*) FILTER (WHERE status = 'in-progress'), 
        'on_hold', COUNT(*) FILTER (WHERE status = 'on-hold'),
        'completed', COUNT(*) FILTER (WHERE status = 'completed'),
        'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled'),
        'high_priority', CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task' AND column_name = 'priority') 
            THEN (SELECT COUNT(*) FROM public.task WHERE priority = 'high')
            ELSE 0 
        END,
        'overdue', CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task' AND column_name = 'due_date') 
            THEN (SELECT COUNT(*) FROM public.task WHERE due_date < CURRENT_DATE AND status NOT IN ('completed', 'cancelled'))
            ELSE 0 
        END
    ) INTO task_stats
    FROM public.task;
    
    -- Estadísticas de conversaciones (si la tabla existe)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'conversation') THEN
        SELECT json_build_object(
            'total', COUNT(*),
            'user_messages', COUNT(*) FILTER (WHERE role = 'user'),
            'assistant_messages', COUNT(*) FILTER (WHERE role = 'assistant'),
            'total_tokens', CASE 
                WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversation' AND column_name = 'tokens_used') 
                THEN (SELECT COALESCE(SUM(tokens_used), 0) FROM public.conversation)
                ELSE 0 
            END,
            'grateful_responses', COUNT(*) FILTER (WHERE user_is_grateful = true)
        ) INTO conversation_stats
        FROM public.conversation;
    ELSE
        conversation_stats := json_build_object(
            'total', 0,
            'user_messages', 0,
            'assistant_messages', 0,
            'total_tokens', 0,
            'grateful_responses', 0
        );
    END IF;
    
    -- Tasa de completación
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            ROUND((COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / COUNT(*)) * 100, 2)
        ELSE 0 
    END INTO completion_rate
    FROM public.task;
    
    -- Tareas activas
    SELECT COUNT(*) INTO active_tasks
    FROM public.task 
    WHERE status IN ('pending', 'in-progress', 'on-hold');
    
    -- Construir resultado final
    SELECT json_build_object(
        'tasks', task_stats,
        'conversations', conversation_stats,
        'completion_rate', completion_rate,
        'active_tasks', active_tasks
    ) INTO result;
    
    RETURN result;
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
GRANT EXECUTE ON FUNCTION motivbot_delete_conversation TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_search_tasks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_get_dashboard TO anon, authenticated;