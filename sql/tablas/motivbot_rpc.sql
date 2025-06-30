-- =====================================================
-- LIMPIAR FUNCIONES EXISTENTES CON ARGUMENTOS ESPECÍFICOS
-- =====================================================

-- Limpiar todas las versiones de motivbot_create_conversation
DROP FUNCTION IF EXISTS motivbot_create_conversation(BIGINT, TEXT, TEXT);
DROP FUNCTION IF EXISTS motivbot_create_conversation(BIGINT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS motivbot_create_conversation(BIGINT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS motivbot_create_conversation(BIGINT, TEXT, TEXT, TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS motivbot_create_conversation(BIGINT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS motivbot_create_conversation(BIGINT, conversation_role, TEXT, VARCHAR(50), VARCHAR(50), VARCHAR(50), INTEGER);

-- Limpiar todas las versiones de otras funciones que pueden tener duplicados
DROP FUNCTION IF EXISTS motivbot_get_tasks(TEXT);
DROP FUNCTION IF EXISTS motivbot_get_tasks(TEXT, TEXT);
DROP FUNCTION IF EXISTS motivbot_get_tasks(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS motivbot_get_tasks(TEXT, TEXT, TEXT[], INTEGER);

DROP FUNCTION IF EXISTS motivbot_create_task(TEXT);
DROP FUNCTION IF EXISTS motivbot_create_task(TEXT, TEXT);
DROP FUNCTION IF EXISTS motivbot_create_task(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS motivbot_create_task(TEXT, TEXT, TEXT, DATE);
DROP FUNCTION IF EXISTS motivbot_create_task(TEXT, TEXT, TEXT, DATE, TIME);
DROP FUNCTION IF EXISTS motivbot_create_task(TEXT, TEXT, TEXT, DATE, TIME, TEXT[]);

DROP FUNCTION IF EXISTS motivbot_update_task(BIGINT);
DROP FUNCTION IF EXISTS motivbot_update_task(BIGINT, TEXT);
DROP FUNCTION IF EXISTS motivbot_update_task(BIGINT, TEXT[]);
DROP FUNCTION IF EXISTS motivbot_update_task(BIGINT, TEXT, TEXT, TEXT, TEXT, DATE, TIME, TEXT[]);

DROP FUNCTION IF EXISTS motivbot_get_conversations(BIGINT);
DROP FUNCTION IF EXISTS motivbot_get_conversations(BIGINT, TEXT);
DROP FUNCTION IF EXISTS motivbot_get_conversations(BIGINT, TEXT, INTEGER);

-- =====================================================
-- FUNCIONES RPC DEFINITIVAS SIN DUPLICADOS
-- =====================================================

-- 1. OBTENER TAREAS (CON SOPORTE COMPLETO PARA TAGS)
CREATE OR REPLACE FUNCTION motivbot_get_tasks(
    p_status TEXT DEFAULT NULL,
    p_priority TEXT DEFAULT NULL,
    p_tags TEXT[] DEFAULT NULL,
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
    has_tags BOOLEAN := FALSE;
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
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'tags'
    ) INTO has_tags;

    -- ✅ DEVOLVER ARRAY DIRECTO (SIN WRAPPER)
    IF p_status IS NOT NULL AND p_priority IS NOT NULL AND p_tags IS NOT NULL AND has_priority AND has_tags THEN
        -- Filtrar por status, priority y tags
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE status = $1::task_status AND priority = $2 AND tags && $3
                ORDER BY %s
                LIMIT $4
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_tags THEN ', ''tags'', tags' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_status, p_priority, p_tags, p_limit INTO result;
        
    ELSIF p_tags IS NOT NULL AND has_tags THEN
        -- Filtrar solo por tags
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE tags && $1
                ORDER BY %s
                LIMIT $2
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_tags THEN ', ''tags'', tags' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING p_tags, p_limit INTO result;
        
    ELSIF p_status IS NOT NULL AND p_priority IS NOT NULL AND has_priority THEN
        -- Filtrar por status y priority (sin tags)
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE status = $1::task_status AND priority = $2
                ORDER BY %s
                LIMIT $3
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_tags THEN ', ''tags'', tags' ELSE '' END,
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
                    ''status'', status%s%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE status = $1::task_status
                ORDER BY %s
                LIMIT $2
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_tags THEN ', ''tags'', tags' ELSE '' END,
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
                    ''status'', status%s%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE priority = $1
                ORDER BY %s
                LIMIT $2
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_tags THEN ', ''tags'', tags' ELSE '' END,
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
                    ''status'', status%s%s%s%s%s%s
                ) as task_json
                FROM public.task 
                ORDER BY %s
                LIMIT $1
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_tags THEN ', ''tags'', tags' ELSE '' END,
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

-- 2. CREAR TAREA (CON SOPORTE COMPLETO PARA TAGS)
CREATE OR REPLACE FUNCTION motivbot_create_task(
    p_title TEXT,
    p_description TEXT DEFAULT NULL,
    p_priority TEXT DEFAULT 'normal',
    p_due_date DATE DEFAULT NULL,
    p_due_time TIME DEFAULT NULL,
    p_tags TEXT[] DEFAULT NULL
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
    has_tags BOOLEAN := FALSE;
    generated_tags TEXT[] := ARRAY[]::TEXT[];
    tags_were_generated BOOLEAN := FALSE;
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
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'tags'
    ) INTO has_tags;
    
    -- Generar tags automáticamente si no se proporcionaron
    IF p_tags IS NULL AND has_tags THEN
        -- Lógica simple de generación de tags basada en título y descripción
        generated_tags := ARRAY[]::TEXT[];
        
        -- Añadir tags basados en palabras clave
        IF LOWER(p_title) LIKE '%urgent%' OR LOWER(p_title) LIKE '%urgente%' THEN
            generated_tags := array_append(generated_tags, 'urgente');
        END IF;
        
        IF LOWER(p_title) LIKE '%project%' OR LOWER(p_title) LIKE '%proyecto%' THEN
            generated_tags := array_append(generated_tags, 'proyecto');
        END IF;
        
        IF LOWER(p_title) LIKE '%test%' OR LOWER(p_title) LIKE '%prueba%' THEN
            generated_tags := array_append(generated_tags, 'test');
        END IF;
        
        IF p_priority = 'high' THEN
            generated_tags := array_append(generated_tags, 'alta-prioridad');
        END IF;
        
        -- Si no se generaron tags, usar un tag por defecto
        IF array_length(generated_tags, 1) IS NULL THEN
            generated_tags := ARRAY['general'];
        END IF;
        
        tags_were_generated := TRUE;
    ELSE
        generated_tags := COALESCE(p_tags, ARRAY[]::TEXT[]);
        tags_were_generated := FALSE;
    END IF;

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
    
    IF has_tags THEN
        insert_query := insert_query || ', tags';
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
    
    IF has_tags THEN
        IF has_priority AND has_due_date AND has_due_time THEN
            insert_query := insert_query || ', $6';
        ELSIF (has_priority AND has_due_date) OR (has_priority AND has_due_time) OR (has_due_date AND has_due_time) THEN
            insert_query := insert_query || ', $5';
        ELSIF has_priority OR has_due_date OR has_due_time THEN
            insert_query := insert_query || ', $4';
        ELSE
            insert_query := insert_query || ', $3';
        END IF;
    END IF;
    
    insert_query := insert_query || ') RETURNING id';
    
    -- Ejecutar inserción según columnas disponibles
    IF has_priority AND has_due_date AND has_due_time AND has_tags THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_priority, p_due_date, p_due_time, generated_tags INTO new_task_id;
    ELSIF has_priority AND has_due_date AND has_tags THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_priority, p_due_date, generated_tags INTO new_task_id;
    ELSIF has_priority AND has_due_time AND has_tags THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_priority, p_due_time, generated_tags INTO new_task_id;
    ELSIF has_due_date AND has_due_time AND has_tags THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_due_date, p_due_time, generated_tags INTO new_task_id;
    ELSIF has_priority AND has_tags THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_priority, generated_tags INTO new_task_id;
    ELSIF has_due_date AND has_tags THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_due_date, generated_tags INTO new_task_id;
    ELSIF has_due_time AND has_tags THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), p_due_time, generated_tags INTO new_task_id;
    ELSIF has_tags THEN
        EXECUTE insert_query USING trim(p_title), NULLIF(trim(p_description), ''), generated_tags INTO new_task_id;
    ELSIF has_priority AND has_due_date AND has_due_time THEN
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
    
    -- ✅ FORMATO COMPATIBLE CON TESTS PYTHON
    SELECT json_build_object(
        'success', true,
        'id', new_task_id,
        'message', 'Task created successfully',
        'tags_generated', tags_were_generated,
        'generated_tags', generated_tags
    ) INTO result;
    
    RETURN result;
END;
$$;

-- 3. CREAR CONVERSACIÓN (VERSIÓN ÚNICA SIN DUPLICADOS)
CREATE OR REPLACE FUNCTION motivbot_create_conversation(
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

-- 4. OBTENER CONVERSACIONES (VERSIÓN ÚNICA)
CREATE OR REPLACE FUNCTION motivbot_get_conversations(
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

-- 3. ACTUALIZAR TAREA (FUNCIÓN CORREGIDA)
CREATE OR REPLACE FUNCTION motivbot_update_task(
    p_task_id BIGINT,
    p_title TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_priority TEXT DEFAULT NULL,
    p_due_date DATE DEFAULT NULL,
    p_due_time TIME DEFAULT NULL,
    p_tags TEXT[] DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    update_query TEXT;
    set_clauses TEXT[] := ARRAY[]::TEXT[];
    param_values TEXT[] := ARRAY[]::TEXT[];
    param_count INTEGER := 1;
    has_priority BOOLEAN := FALSE;
    has_due_date BOOLEAN := FALSE;
    has_due_time BOOLEAN := FALSE;
    has_tags BOOLEAN := FALSE;
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
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'tags'
    ) INTO has_tags;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    -- Construir cláusulas SET dinámicamente
    IF p_title IS NOT NULL THEN
        param_count := param_count + 1;
        set_clauses := array_append(set_clauses, format('title = $%s', param_count));
        param_values := array_append(param_values, trim(p_title));
    END IF;
    
    IF p_description IS NOT NULL THEN
        param_count := param_count + 1;
        set_clauses := array_append(set_clauses, format('description = $%s', param_count));
        param_values := array_append(param_values, NULLIF(trim(p_description), ''));
    END IF;
    
    IF p_status IS NOT NULL THEN
        param_count := param_count + 1;
        set_clauses := array_append(set_clauses, format('status = $%s::task_status', param_count));
        param_values := array_append(param_values, p_status);
    END IF;
    
    IF p_priority IS NOT NULL AND has_priority THEN
        param_count := param_count + 1;
        set_clauses := array_append(set_clauses, format('priority = $%s', param_count));
        param_values := array_append(param_values, p_priority);
    END IF;
    
    IF p_due_date IS NOT NULL AND has_due_date THEN
        param_count := param_count + 1;
        set_clauses := array_append(set_clauses, format('due_date = $%s', param_count));
        param_values := array_append(param_values, p_due_date::TEXT);
    END IF;
    
    IF p_due_time IS NOT NULL AND has_due_time THEN
        param_count := param_count + 1;
        set_clauses := array_append(set_clauses, format('due_time = $%s', param_count));
        param_values := array_append(param_values, p_due_time::TEXT);
    END IF;
    
    IF p_tags IS NOT NULL AND has_tags THEN
        param_count := param_count + 1;
        set_clauses := array_append(set_clauses, format('tags = $%s', param_count));
        param_values := array_append(param_values, array_to_string(p_tags, ','));
    END IF;
    
    IF has_updated_at THEN
        set_clauses := array_append(set_clauses, 'updated_at = CURRENT_TIMESTAMP');
    END IF;
    
    -- Si no hay nada que actualizar
    IF array_length(set_clauses, 1) IS NULL OR array_length(set_clauses, 1) = 0 THEN
        RETURN json_build_object(
            'success', false,
            'message', 'No fields to update'
        );
    END IF;
    
    -- Construir query completo
    update_query := format('UPDATE public.task SET %s WHERE id = $1', array_to_string(set_clauses, ', '));
    
    -- Ejecutar update con manejo simplificado
    BEGIN
        IF p_title IS NOT NULL AND p_description IS NOT NULL AND p_status IS NOT NULL THEN
            EXECUTE update_query USING p_task_id, trim(p_title), NULLIF(trim(p_description), ''), p_status;
        ELSIF p_title IS NOT NULL AND p_status IS NOT NULL THEN
            EXECUTE update_query USING p_task_id, trim(p_title), p_status;
        ELSIF p_title IS NOT NULL AND p_tags IS NOT NULL AND has_tags THEN
            EXECUTE update_query USING p_task_id, trim(p_title), p_tags;
        ELSIF p_tags IS NOT NULL AND has_tags THEN
            EXECUTE update_query USING p_task_id, p_tags;
        ELSIF p_title IS NOT NULL THEN
            EXECUTE update_query USING p_task_id, trim(p_title);
        ELSIF p_status IS NOT NULL THEN
            EXECUTE update_query USING p_task_id, p_status;
        ELSIF p_due_date IS NOT NULL AND p_due_time IS NOT NULL THEN
            EXECUTE update_query USING p_task_id, p_due_date, p_due_time;
        ELSIF p_due_date IS NOT NULL THEN
            EXECUTE update_query USING p_task_id, p_due_date;
        ELSIF p_due_time IS NOT NULL THEN
            EXECUTE update_query USING p_task_id, p_due_time;
        ELSE
            -- Fallback genérico para otros casos
            EXECUTE format('UPDATE public.task SET %s WHERE id = %s', 
                          array_to_string(set_clauses, ', '), p_task_id);
        END IF;
        
        EXCEPTION WHEN OTHERS THEN
            RETURN json_build_object(
                'success', false,
                'message', 'Error updating task: ' || SQLERRM
            );
    END;
    
    -- ✅ FORMATO COMPATIBLE CON TESTS PYTHON
    SELECT json_build_object(
        'success', true,
        'message', 'Task updated successfully',
        'id', p_task_id
    ) INTO result;
    
    RETURN result;
END;
$$;

-- 5. BUSCAR TAREAS (FUNCIÓN FALTANTE)
CREATE OR REPLACE FUNCTION motivbot_search_tasks(
    p_search TEXT,
    p_search_tags BOOLEAN DEFAULT false,
    p_limit INTEGER DEFAULT 50
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    has_tags BOOLEAN := FALSE;
    has_created_at BOOLEAN := FALSE;
    has_updated_at BOOLEAN := FALSE;
    has_due_date BOOLEAN := FALSE;
    has_due_time BOOLEAN := FALSE;
    has_priority BOOLEAN := FALSE;
BEGIN
    -- Verificar qué columnas existen
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'tags'
    ) INTO has_tags;
    
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

    -- Buscar en título, descripción y opcionalmente en tags
    IF p_search_tags AND has_tags THEN
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE LOWER(title) LIKE LOWER($1) 
                   OR LOWER(description) LIKE LOWER($1)
                   OR EXISTS (
                       SELECT 1 FROM unnest(tags) as tag 
                       WHERE LOWER(tag) LIKE LOWER($1)
                   )
                ORDER BY %s
                LIMIT $2
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_tags THEN ', ''tags'', tags' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING '%' || p_search || '%', p_limit INTO result;
    ELSE
        EXECUTE format('
            SELECT COALESCE(json_agg(task_json), ''[]''::json)
            FROM (
                SELECT json_build_object(
                    ''id'', id,
                    ''title'', title,
                    ''description'', description,
                    ''status'', status%s%s%s%s%s%s
                ) as task_json
                FROM public.task 
                WHERE LOWER(title) LIKE LOWER($1) 
                   OR LOWER(description) LIKE LOWER($1)
                ORDER BY %s
                LIMIT $2
            ) tasks',
            CASE WHEN has_priority THEN ', ''priority'', priority' ELSE '' END,
            CASE WHEN has_tags THEN ', ''tags'', tags' ELSE '' END,
            CASE WHEN has_due_date THEN ', ''due_date'', due_date' ELSE '' END,
            CASE WHEN has_due_time THEN ', ''due_time'', due_time' ELSE '' END,
            CASE WHEN has_created_at THEN ', ''created_at'', created_at' ELSE '' END,
            CASE WHEN has_updated_at THEN ', ''updated_at'', updated_at' ELSE '' END,
            CASE WHEN has_created_at THEN 'created_at DESC' ELSE 'id DESC' END
        ) USING '%' || p_search || '%', p_limit INTO result;
    END IF;
    
    RETURN result;
END;
$$;

-- 6. ACTUALIZAR FEEDBACK DE CONVERSACIÓN (FUNCIÓN CORREGIDA)
CREATE OR REPLACE FUNCTION motivbot_update_conversation_feedback(
    p_conversation_id BIGINT,
    p_user_is_grateful BOOLEAN DEFAULT NULL,
    p_user_is_useful BOOLEAN DEFAULT NULL,
    p_assistant_is_useful BOOLEAN DEFAULT NULL,
    p_assistant_is_precise BOOLEAN DEFAULT NULL,
    p_assistant_is_grateful BOOLEAN DEFAULT NULL,
    p_emotional_state TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    update_query TEXT;
    set_clauses TEXT[] := ARRAY[]::TEXT[];
    has_emotional_state BOOLEAN := FALSE;
    has_updated_at BOOLEAN := FALSE;
BEGIN
    -- Verificar que la conversación existe
    IF NOT EXISTS (SELECT 1 FROM public.conversation WHERE id = p_conversation_id) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Conversation not found'
        );
    END IF;
    
    -- Verificar qué columnas existen
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'emotional_state'
    ) INTO has_emotional_state;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    -- Construir cláusulas SET dinámicamente (CORREGIDO)
    IF p_user_is_grateful IS NOT NULL THEN
        set_clauses := array_append(set_clauses, 'user_is_grateful = ' || p_user_is_grateful::TEXT);
    END IF;
    
    IF p_user_is_useful IS NOT NULL THEN
        set_clauses := array_append(set_clauses, 'user_is_useful = ' || p_user_is_useful::TEXT);
    END IF;
    
    IF p_assistant_is_useful IS NOT NULL THEN
        set_clauses := array_append(set_clauses, 'assistant_is_useful = ' || p_assistant_is_useful::TEXT);
    END IF;
    
    IF p_assistant_is_precise IS NOT NULL THEN
        set_clauses := array_append(set_clauses, 'assistant_is_precise = ' || p_assistant_is_precise::TEXT);
    END IF;
    
    IF p_assistant_is_grateful IS NOT NULL THEN
        set_clauses := array_append(set_clauses, 'assistant_is_grateful = ' || p_assistant_is_grateful::TEXT);
    END IF;
    
    IF p_emotional_state IS NOT NULL AND has_emotional_state THEN
        set_clauses := array_append(set_clauses, 'emotional_state = ''' || p_emotional_state || '''');
    END IF;
    
    IF has_updated_at THEN
        set_clauses := array_append(set_clauses, 'updated_at = CURRENT_TIMESTAMP');
    END IF;
    
    -- Si no hay nada que actualizar
    IF array_length(set_clauses, 1) IS NULL OR array_length(set_clauses, 1) = 0 THEN
        RETURN json_build_object(
            'success', false,
            'message', 'No fields to update'
        );
    END IF;
    
    -- Construir y ejecutar query (CORREGIDO)
    update_query := 'UPDATE public.conversation SET ' || 
                   array_to_string(set_clauses, ', ') || 
                   ' WHERE id = ' || p_conversation_id::TEXT;
    
    BEGIN
        EXECUTE update_query;
        
        EXCEPTION WHEN OTHERS THEN
            RETURN json_build_object(
                'success', false,
                'message', 'Error updating conversation feedback: ' || SQLERRM
            );
    END;
    
    -- ✅ FORMATO COMPATIBLE CON TESTS PYTHON
    SELECT json_build_object(
        'success', true,
        'message', 'Conversation feedback updated successfully',
        'id', p_conversation_id
    ) INTO result;
    
    RETURN result;
END;
$$;

-- 7. ELIMINAR CONVERSACIÓN (FUNCIÓN FALTANTE)
CREATE OR REPLACE FUNCTION motivbot_delete_conversation(
    p_conversation_id BIGINT
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
    
    -- Eliminar la conversación
    DELETE FROM public.conversation WHERE id = p_conversation_id;
    
    -- ✅ FORMATO COMPATIBLE CON TESTS PYTHON
    SELECT json_build_object(
        'success', true,
        'message', 'Conversation deleted successfully',
        'id', p_conversation_id
    ) INTO result;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Error deleting conversation: ' || SQLERRM
        );
END;
$$;

-- 8. ELIMINAR TAREA (FUNCIÓN FALTANTE)
CREATE OR REPLACE FUNCTION motivbot_delete_task(
    p_task_id BIGINT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Verificar que la tarea existe
    IF NOT EXISTS (SELECT 1 FROM public.task WHERE id = p_task_id) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Task not found'
        );
    END IF;
    
    -- Eliminar conversaciones asociadas primero (si existen)
    DELETE FROM public.conversation WHERE task_id = p_task_id;
    
    -- Eliminar la tarea
    DELETE FROM public.task WHERE id = p_task_id;
    
    -- ✅ FORMATO COMPATIBLE CON TESTS PYTHON
    SELECT json_build_object(
        'success', true,
        'message', 'Task deleted successfully',
        'id', p_task_id
    ) INTO result;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Error deleting task: ' || SQLERRM
        );
END;
$$;

-- 9. OBTENER DASHBOARD (FUNCIÓN CORREGIDA)
CREATE OR REPLACE FUNCTION motivbot_get_dashboard()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    task_stats JSON;
    conversation_stats JSON;
    tag_stats JSON;
    completion_rate NUMERIC;
    active_tasks INTEGER;
    has_tags BOOLEAN := FALSE;
    has_priority BOOLEAN := FALSE;
    has_due_date BOOLEAN := FALSE;
    has_tokens_used BOOLEAN := FALSE;
BEGIN
    -- Verificar qué columnas existen
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'task' AND column_name = 'tags'
    ) INTO has_tags;
    
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
        WHERE table_schema = 'public' AND table_name = 'conversation' AND column_name = 'tokens_used'
    ) INTO has_tokens_used;
    
    -- Estadísticas de tareas (CORREGIDO: usar guiones en lugar de guiones bajos)
    IF has_priority AND has_due_date THEN
        SELECT json_build_object(
            'total', COUNT(*),
            'pending', COUNT(*) FILTER (WHERE status = 'pending'),
            'in_progress', COUNT(*) FILTER (WHERE status = 'in-progress'),
            'on_hold', COUNT(*) FILTER (WHERE status = 'on-hold'),
            'completed', COUNT(*) FILTER (WHERE status = 'completed'),
            'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled'),
            'high_priority', COUNT(*) FILTER (WHERE priority = 'high'),
            'overdue', COUNT(*) FILTER (WHERE due_date < CURRENT_DATE AND status NOT IN ('completed', 'cancelled'))
        ) INTO task_stats FROM public.task;
    ELSE
        SELECT json_build_object(
            'total', COUNT(*),
            'pending', COUNT(*) FILTER (WHERE status = 'pending'),
            'in_progress', COUNT(*) FILTER (WHERE status = 'in-progress'),
            'on_hold', COUNT(*) FILTER (WHERE status = 'on-hold'),
            'completed', COUNT(*) FILTER (WHERE status = 'completed'),
            'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled'),
            'high_priority', 0,
            'overdue', 0
        ) INTO task_stats FROM public.task;
    END IF;
    
    -- Estadísticas de conversaciones
    IF has_tokens_used THEN
        SELECT json_build_object(
            'total', COUNT(*),
            'user_messages', COUNT(*) FILTER (WHERE role = 'user'),
            'assistant_messages', COUNT(*) FILTER (WHERE role = 'assistant'),
            'total_tokens', COALESCE(SUM(tokens_used), 0),
            'grateful_responses', COUNT(*) FILTER (WHERE user_is_grateful = true)
        ) INTO conversation_stats FROM public.conversation;
    ELSE
        SELECT json_build_object(
            'total', COUNT(*),
            'user_messages', COUNT(*) FILTER (WHERE role = 'user'),
            'assistant_messages', COUNT(*) FILTER (WHERE role = 'assistant'),
            'total_tokens', 0,
            'grateful_responses', COUNT(*) FILTER (WHERE user_is_grateful = true)
        ) INTO conversation_stats FROM public.conversation;
    END IF;
    
    -- Estadísticas de tags
    IF has_tags THEN
        WITH tag_counts AS (
            SELECT unnest(tags) as tag, COUNT(*) as count
            FROM public.task 
            WHERE tags IS NOT NULL
            GROUP BY unnest(tags)
            ORDER BY count DESC
            LIMIT 10
        )
        SELECT json_build_object(
            'total_unique', COUNT(DISTINCT tag),
            'most_used', COALESCE(json_agg(json_build_object('tag', tag, 'count', count)), '[]'::json)
        ) INTO tag_stats FROM tag_counts;
    ELSE
        tag_stats := json_build_object('total_unique', 0, 'most_used', '[]'::json);
    END IF;
    
    -- Calcular tasa de completitud
    SELECT CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND((COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / COUNT(*)) * 100, 2)
    END INTO completion_rate FROM public.task;
    
    -- Calcular tareas activas (CORREGIDO: usar guiones)
    SELECT COUNT(*) INTO active_tasks 
    FROM public.task 
    WHERE status IN ('pending', 'in-progress', 'on-hold');
    
    -- Construir resultado final
    SELECT json_build_object(
        'tasks', task_stats,
        'conversations', conversation_stats,
        'tags', tag_stats,
        'completion_rate', completion_rate,
        'active_tasks', active_tasks
    ) INTO result;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Error retrieving dashboard: ' || SQLERRM
        );
END;
$$;

-- Otorgar permisos para todas las funciones
GRANT EXECUTE ON FUNCTION motivbot_get_tasks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_create_task TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_update_task TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_create_conversation TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_get_conversations TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_search_tasks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_update_conversation_feedback TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_delete_conversation TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_delete_task TO anon, authenticated;
GRANT EXECUTE ON FUNCTION motivbot_get_dashboard TO anon, authenticated;