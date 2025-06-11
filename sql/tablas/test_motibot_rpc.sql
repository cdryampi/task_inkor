-- =====================================================
-- TEST SUITE PARA MOTIVBOT RPC FUNCTIONS
-- Archivo para probar todas las funciones RPC
-- =====================================================

-- Configurar el entorno de pruebas
SET client_min_messages TO NOTICE;

DO $$
BEGIN
    RAISE NOTICE '🚀 Iniciando tests de MotivBot RPC Functions';
    RAISE NOTICE '================================================';
END $$;

-- =====================================================
-- 1. TESTS PARA FUNCIONES DE TAREAS
-- =====================================================

DO $$
DECLARE
    test_result JSON;
    task_id INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📝 TESTING: Funciones de Tareas';
    RAISE NOTICE '================================';
    
    -- Test 1: Crear nueva tarea
    RAISE NOTICE '🧪 Test 1: motivbot_create_task';
    SELECT motivbot_create_task(
        'Tarea de prueba RPC',
        'Esta es una tarea creada desde el test RPC',
        'pending',
        'high',
        CURRENT_DATE + INTERVAL '3 days',
        '15:30:00'
    ) INTO test_result;
    
    -- Extraer el ID de la tarea creada
    task_id := (test_result->'task'->>'id')::INTEGER;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Task created successfully with ID: %', task_id;
    ELSE
        RAISE NOTICE '❌ Failed to create task: %', test_result->>'message';
    END IF;
    
    -- Test 2: Obtener tareas con filtros
    RAISE NOTICE '🧪 Test 2: motivbot_get_tasks (all tasks)';
    SELECT motivbot_get_tasks() INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Tasks retrieved: % total tasks found', 
            test_result->>'total_count';
    ELSE
        RAISE NOTICE '❌ Failed to get tasks';
    END IF;
    
    -- Test 3: Obtener tareas con filtros específicos
    RAISE NOTICE '🧪 Test 3: motivbot_get_tasks (filtered by status)';
    SELECT motivbot_get_tasks(
        p_status => 'pending',
        p_limit => 5,
        p_order_by => 'priority'
    ) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Filtered tasks retrieved: % pending tasks', 
            jsonb_array_length((test_result->'tasks')::jsonb);
    ELSE
        RAISE NOTICE '❌ Failed to get filtered tasks';
    END IF;
    
    -- Test 4: Búsqueda de tareas
    RAISE NOTICE '🧪 Test 4: motivbot_get_tasks (search functionality)';
    SELECT motivbot_get_tasks(
        p_search => 'proyecto',
        p_limit => 10
    ) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Search completed: % tasks found with "proyecto"', 
            jsonb_array_length((test_result->'tasks')::jsonb);
    ELSE
        RAISE NOTICE '❌ Search failed';
    END IF;
    
    -- Test 5: Actualizar tarea
    RAISE NOTICE '🧪 Test 5: motivbot_update_task';
    SELECT motivbot_update_task(
        task_id,
        p_title => 'Tarea actualizada via RPC',
        p_status => 'completed',
        p_priority => 'medium'
    ) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Task updated successfully';
    ELSE
        RAISE NOTICE '❌ Failed to update task: %', test_result->>'message';
    END IF;
    
    -- Test 6: Intentar actualizar tarea inexistente
    RAISE NOTICE '🧪 Test 6: motivbot_update_task (non-existent task)';
    SELECT motivbot_update_task(
        99999,
        p_title => 'Should fail'
    ) INTO test_result;
    
    IF test_result->>'success' = 'false' THEN
        RAISE NOTICE '✅ Correctly handled non-existent task';
    ELSE
        RAISE NOTICE '❌ Should have failed for non-existent task';
    END IF;
    
END $$;

-- =====================================================
-- 2. TESTS PARA FUNCIONES DE CONVERSACIONES
-- =====================================================

DO $$
DECLARE
    test_result JSON;
    conversation_id INTEGER;
    sample_task_id INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '💬 TESTING: Funciones de Conversaciones';
    RAISE NOTICE '=====================================';
    
    -- Obtener un task_id existente para las pruebas
    SELECT id INTO sample_task_id FROM public.Task LIMIT 1;
    
    IF sample_task_id IS NULL THEN
        RAISE NOTICE '⚠️  No tasks found, creating one for conversation tests';
        SELECT (motivbot_create_task('Task for conversation test')->'task'->>'id')::INTEGER 
        INTO sample_task_id;
    END IF;
    
    -- Test 1: Añadir conversación GPT
    RAISE NOTICE '🧪 Test 1: add_gpt_conversation';
    SELECT add_gpt_conversation(
        sample_task_id,
        'assistant',
        '¡Hola! Soy MotivBot y estoy aquí para ayudarte. Esta es una conversación de prueba desde RPC. ¿En qué puedo asistirte hoy? 🚀',
        'rpc_test',
        'gpt-4-test',
        42
    ) INTO test_result;
    
    conversation_id := (test_result->'conversation'->>'id')::INTEGER;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ GPT conversation added with ID: %', conversation_id;
    ELSE
        RAISE NOTICE '❌ Failed to add GPT conversation: %', test_result->>'message';
    END IF;
    
    -- Test 2: Obtener conversaciones por tarea
    RAISE NOTICE '🧪 Test 2: motivbot_get_conversations (by task)';
    SELECT motivbot_get_conversations(
        p_task_id => sample_task_id,
        p_include_task_info => true
    ) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Conversations retrieved: % conversations for task %', 
            jsonb_array_length((test_result->'conversations')::jsonb),
            sample_task_id;
    ELSE
        RAISE NOTICE '❌ Failed to get conversations by task';
    END IF;
    
    -- Test 3: Obtener conversaciones por rol
    RAISE NOTICE '🧪 Test 3: motivbot_get_conversations (by role)';
    SELECT motivbot_get_conversations(
        p_role => 'assistant',
        p_limit => 10
    ) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Assistant conversations retrieved: % conversations', 
            jsonb_array_length((test_result->'conversations')::jsonb);
    ELSE
        RAISE NOTICE '❌ Failed to get conversations by role';
    END IF;
    
    -- Test 4: Búsqueda en conversaciones
    RAISE NOTICE '🧪 Test 4: motivbot_get_conversations (search)';
    SELECT motivbot_get_conversations(
        p_search => 'MotivBot',
        p_limit => 5
    ) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Search in conversations completed: % results', 
            jsonb_array_length((test_result->'conversations')::jsonb);
    ELSE
        RAISE NOTICE '❌ Search in conversations failed';
    END IF;
    
    -- Test 5: Actualizar feedback de conversación
    RAISE NOTICE '🧪 Test 5: update_conversation_feedback';
    SELECT update_conversation_feedback(
        conversation_id,
        p_assistant_is_useful => true,
        p_assistant_is_precise => true,
        p_assistant_is_grateful => false
    ) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Conversation feedback updated successfully';
    ELSE
        RAISE NOTICE '❌ Failed to update conversation feedback: %', test_result->>'message';
    END IF;
    
    -- Test 6: Obtener historial completo de tarea
    RAISE NOTICE '🧪 Test 6: get_task_conversation_history';
    SELECT get_task_conversation_history(sample_task_id) INTO test_result;
    
    IF test_result->'task_info' IS NOT NULL THEN
        RAISE NOTICE '✅ Task conversation history retrieved successfully';
        RAISE NOTICE '   Task: %', test_result->'task_info'->>'title';
        RAISE NOTICE '   Conversations: %', jsonb_array_length((test_result->'conversations')::jsonb);
        RAISE NOTICE '   Stats: % total conversations, % tokens used', 
            test_result->'stats'->>'total_conversations',
            test_result->'stats'->>'total_tokens';
    ELSE
        RAISE NOTICE '❌ Failed to get task conversation history';
    END IF;
    
END $$;

-- =====================================================
-- 3. TESTS PARA FUNCIONES DE ANÁLISIS
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📊 TESTING: Funciones de Análisis';
    RAISE NOTICE '=================================';
    
    -- Test 1: Dashboard completo
    RAISE NOTICE '🧪 Test 1: motivbot_get_dashboard';
    SELECT motivbot_get_dashboard() INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Dashboard data retrieved successfully';
        RAISE NOTICE '   Total tasks: %', test_result->'dashboard'->'tasks_summary'->>'total_tasks';
        RAISE NOTICE '   Pending tasks: %', test_result->'dashboard'->'tasks_summary'->>'pending_tasks';
        RAISE NOTICE '   Completed tasks: %', test_result->'dashboard'->'tasks_summary'->>'completed_tasks';
        RAISE NOTICE '   High priority tasks: %', test_result->'dashboard'->'tasks_summary'->>'high_priority_tasks';
        RAISE NOTICE '   Total conversations: %', test_result->'dashboard'->'conversations_summary'->>'total_conversations';
        RAISE NOTICE '   User messages: %', test_result->'dashboard'->'conversations_summary'->>'user_messages';
        RAISE NOTICE '   Assistant messages: %', test_result->'dashboard'->'conversations_summary'->>'assistant_messages';
        RAISE NOTICE '   Total tokens used: %', test_result->'dashboard'->'conversations_summary'->>'total_tokens';
    ELSE
        RAISE NOTICE '❌ Failed to get dashboard data';
    END IF;
    
    -- Test 2: Métricas de rendimiento
    RAISE NOTICE '🧪 Test 2: motivbot_get_performance_metrics (7 days)';
    SELECT motivbot_get_performance_metrics(7) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Performance metrics retrieved successfully';
        RAISE NOTICE '   Period: % days back', test_result->'period'->>'days_back';
        RAISE NOTICE '   Grateful percentage: %', test_result->'metrics'->'user_satisfaction'->>'grateful_percentage';
        RAISE NOTICE '   Useful percentage: %', test_result->'metrics'->'user_satisfaction'->>'useful_percentage';
        RAISE NOTICE '   Assistant total responses: %', test_result->'metrics'->'assistant_performance'->>'total_responses';
        RAISE NOTICE '   Average response time: % ms', test_result->'metrics'->'assistant_performance'->>'avg_response_time_ms';
        RAISE NOTICE '   Total tokens used: %', test_result->'metrics'->'assistant_performance'->>'total_tokens_used';
    ELSE
        RAISE NOTICE '❌ Failed to get performance metrics';
    END IF;
    
    -- Test 3: Métricas de rendimiento (30 days)
    RAISE NOTICE '🧪 Test 3: motivbot_get_performance_metrics (30 days)';
    SELECT motivbot_get_performance_metrics(30) INTO test_result;
    
    IF test_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Extended performance metrics retrieved successfully';
        RAISE NOTICE '   Extended period: % days', test_result->'period'->>'days_back';
    ELSE
        RAISE NOTICE '❌ Failed to get extended performance metrics';
    END IF;
    
    -- Test 4: Resumen de conversaciones
    RAISE NOTICE '🧪 Test 4: get_conversation_summary';
    SELECT get_conversation_summary(NULL, 25) INTO test_result;
    
    IF test_result->'conversations' IS NOT NULL THEN
        RAISE NOTICE '✅ Conversation summary retrieved successfully';
        RAISE NOTICE '   Conversations returned: %', jsonb_array_length((test_result->'conversations')::jsonb);
        RAISE NOTICE '   Summary total conversations: %', test_result->'summary'->>'total_conversations';
        RAISE NOTICE '   Unique tasks: %', test_result->'summary'->>'unique_tasks';
        RAISE NOTICE '   Total tokens: %', test_result->'summary'->>'total_tokens';
    ELSE
        RAISE NOTICE '❌ Failed to get conversation summary';
    END IF;
    
END $$;

-- =====================================================
-- 4. TESTS DE VALIDACIÓN Y EDGE CASES
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🧨 TESTING: Validación y Edge Cases';
    RAISE NOTICE '===================================';
    
    -- Test 1: Crear tarea sin título (debería fallar)
    RAISE NOTICE '🧪 Test 1: motivbot_create_task (without title)';
    SELECT motivbot_create_task('') INTO test_result;
    
    IF test_result->>'success' = 'false' THEN
        RAISE NOTICE '✅ Correctly rejected empty title';
    ELSE
        RAISE NOTICE '❌ Should have rejected empty title';
    END IF;
    
    -- Test 2: Crear tarea con status inválido
    RAISE NOTICE '🧪 Test 2: motivbot_create_task (invalid status)';
    SELECT motivbot_create_task(
        'Test task',
        'Description',
        'invalid_status'
    ) INTO test_result;
    
    IF test_result->>'success' = 'false' THEN
        RAISE NOTICE '✅ Correctly rejected invalid status';
    ELSE
        RAISE NOTICE '❌ Should have rejected invalid status';
    END IF;
    
    -- Test 3: Crear tarea con prioridad inválida
    RAISE NOTICE '🧪 Test 3: motivbot_create_task (invalid priority)';
    SELECT motivbot_create_task(
        'Test task',
        'Description',
        'pending',
        'super_high'
    ) INTO test_result;
    
    IF test_result->>'success' = 'false' THEN
        RAISE NOTICE '✅ Correctly rejected invalid priority';
    ELSE
        RAISE NOTICE '❌ Should have rejected invalid priority';
    END IF;
    
    -- Test 4: Obtener conversaciones de tarea inexistente
    RAISE NOTICE '🧪 Test 4: motivbot_get_conversations (non-existent task)';
    SELECT motivbot_get_conversations(p_task_id => 99999) INTO test_result;
    
    IF test_result->>'success' = 'true' AND jsonb_array_length((test_result->'conversations')::jsonb) = 0 THEN
        RAISE NOTICE '✅ Correctly handled non-existent task (returned empty array)';
    ELSE
        RAISE NOTICE '❌ Unexpected result for non-existent task';
    END IF;
    
    -- Test 5: Añadir conversación a tarea inexistente
    RAISE NOTICE '🧪 Test 5: add_gpt_conversation (non-existent task)';
    SELECT add_gpt_conversation(
        99999,
        'assistant',
        'This should fail'
    ) INTO test_result;
    
    IF test_result->>'success' = 'false' THEN
        RAISE NOTICE '✅ Correctly rejected conversation for non-existent task';
    ELSE
        RAISE NOTICE '❌ Should have rejected conversation for non-existent task';
    END IF;
    
END $$;

-- =====================================================
-- 5. CLEANUP Y RESUMEN FINAL
-- =====================================================

DO $$
DECLARE
    task_count INTEGER;
    conversation_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🧹 CLEANUP: Estado final de la base de datos';
    RAISE NOTICE '=============================================';
    
    SELECT COUNT(*) INTO task_count FROM public.Task;
    SELECT COUNT(*) INTO conversation_count FROM public.Conversation;
    
    RAISE NOTICE '📊 Final database state:';
    RAISE NOTICE '   Total tasks: %', task_count;
    RAISE NOTICE '   Total conversations: %', conversation_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ All MotivBot RPC function tests completed!';
    RAISE NOTICE '================================================';
    
END $$;

-- Verificar que todas las funciones existen
DO $$
DECLARE
    missing_functions TEXT[] := '{}';
    function_name TEXT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 VERIFICATION: Checking all RPC functions exist';
    RAISE NOTICE '=================================================';
    
    -- Lista de funciones que deberían existir
    FOR function_name IN 
        SELECT unnest(ARRAY[
            'motivbot_get_tasks',
            'motivbot_create_task', 
            'motivbot_update_task',
            'motivbot_delete_task',
            'motivbot_get_conversations',
            'motivbot_get_dashboard',
            'motivbot_get_performance_metrics',
            'get_task_conversation_history',
            'add_gpt_conversation',
            'update_conversation_feedback',
            'get_conversation_summary',
            'cleanup_old_conversations'
        ])
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = function_name
        ) THEN
            missing_functions := array_append(missing_functions, function_name);
        END IF;
    END LOOP;
    
    IF array_length(missing_functions, 1) > 0 THEN
        RAISE NOTICE '❌ Missing functions detected:';
        FOR function_name IN SELECT unnest(missing_functions) LOOP
            RAISE NOTICE '   - %', function_name;
        END LOOP;
    ELSE
        RAISE NOTICE '✅ All required RPC functions are present!';
    END IF;
    
END $$;