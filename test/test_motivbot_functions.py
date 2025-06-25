import pytest
import requests
import json
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

@pytest.fixture
def supabase_config():
    """Configuración de Supabase"""
    return {
        'url': os.getenv('VITE_SUPABASE_URL'),
        'anon_key': os.getenv('VITE_SUPABASE_ANON_KEY'),
    }

@pytest.fixture
def headers(supabase_config):
    """Headers para las peticiones HTTP"""
    return {
        'apikey': supabase_config['anon_key'],
        'Authorization': f"Bearer {supabase_config['anon_key']}",
        'Content-Type': 'application/json',
    }

@pytest.fixture
def cleanup_tasks():
    """Fixture para limpiar tareas creadas durante los tests"""
    created_tasks = []
    
    def add_task(task_id):
        """Agregar tarea para cleanup"""
        created_tasks.append(task_id)
    
    yield add_task
    
    # Cleanup después de todos los tests
    if created_tasks:
        print(f"\n🧹 Cleaning up {len(created_tasks)} test tasks...")
        supabase_url = os.getenv('VITE_SUPABASE_URL')
        supabase_key = os.getenv('VITE_SUPABASE_ANON_KEY')
        
        headers = {
            'apikey': supabase_key,
            'Authorization': f"Bearer {supabase_key}",
            'Content-Type': 'application/json',
        }
        
        delete_url = f"{supabase_url}/rest/v1/rpc/motivbot_delete_task"
        
        for task_id in created_tasks:
            try:
                response = requests.post(delete_url, headers=headers, json={"p_task_id": task_id})
                if response.status_code == 200:
                    result = response.json()
                    if result.get('success'):
                        print(f"✅ Deleted task {task_id}")
                    else:
                        print(f"⚠️  Failed to delete task {task_id}: {result.get('message')}")
                else:
                    print(f"❌ Error deleting task {task_id}: HTTP {response.status_code}")
            except Exception as e:
                print(f"❌ Exception deleting task {task_id}: {e}")

class TestMotivbotRPCFunctions:
    
    def test_motivbot_get_dashboard(self, supabase_config, headers):
        """Test de la función dashboard por HTTP"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_dashboard"
        
        response = requests.post(url, headers=headers, json={})
        
        assert response.status_code == 200
        result = response.json()
        
        # Verificar estructura del dashboard
        assert 'tasks' in result
        assert 'conversations' in result
        assert 'completion_rate' in result
        assert 'active_tasks' in result
        
        # ✅ NUEVO: Verificar estadísticas de tags
        assert 'tags' in result
        assert 'total_unique' in result['tags']
        assert 'most_used' in result['tags']
        
    def test_motivbot_create_task(self, supabase_config, headers, cleanup_tasks):
        """Test crear tarea por HTTP"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        
        payload = {
            "p_title": "Test Task HTTP - Cleanup",
            "p_description": "Test Description - Will be deleted",
            "p_priority": "normal"
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert 'id' in result
        assert result['message'] == 'Task created successfully'
        
        # ✅ NUEVO: Verificar campos relacionados con tags
        assert 'tags_generated' in result
        assert 'generated_tags' in result
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(result['id'])
        
    def test_motivbot_create_task_with_tags(self, supabase_config, headers, cleanup_tasks):
        """✅ NUEVO: Test crear tarea con tags específicos"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        
        payload = {
            "p_title": "Task with Custom Tags - Cleanup",
            "p_description": "Testing custom tags functionality",
            "p_priority": "high",
            "p_tags": ["test", "urgente", "desarrollo"]
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert 'id' in result
        assert result['tags_generated'] is False  # No generados automáticamente
        assert result['generated_tags'] == ["test", "urgente", "desarrollo"]
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(result['id'])
        
    def test_motivbot_get_tasks(self, supabase_config, headers):
        """Test obtener tareas por HTTP"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_tasks"
        
        response = requests.post(url, headers=headers, json={})
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
        # ✅ NUEVO: Si hay tareas, verificar que incluyan tags
        if len(result) > 0:
            task = result[0]
            assert 'id' in task
            assert 'title' in task
            # Verificar que tags esté presente (puede ser null/empty)
            assert 'tags' in task
        
    def test_motivbot_get_tasks_with_filters(self, supabase_config, headers):
        """Test obtener tareas con filtros por HTTP"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_tasks"
        
        payload = {
            "p_status": "pending",
            "p_priority": "normal",
            "p_limit": 10
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
    def test_motivbot_get_tasks_by_tags(self, supabase_config, headers, cleanup_tasks):
        """✅ NUEVO: Test filtrar tareas por tags"""
        # Crear tarea con tags específicos
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Task for Tag Filter - Cleanup",
            "p_tags": ["test-filter", "unique-tag"]
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        assert create_response.status_code == 200
        task_result = create_response.json()
        task_id = task_result['id']
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(task_id)
        
        # Filtrar por tags
        filter_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_tasks"
        filter_payload = {
            "p_tags": ["test-filter"],
            "p_limit": 50
        }
        
        response = requests.post(filter_url, headers=headers, json=filter_payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
        # Verificar que al menos nuestra tarea esté en los resultados
        task_ids = [task['id'] for task in result]
        assert task_id in task_ids
        
    def test_motivbot_create_task_validation(self, supabase_config, headers):
        """Test validación al crear tarea sin título"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        
        payload = {
            "p_title": None
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is False
        assert 'title' in result['message'].lower() or 'required' in result['message'].lower()

    def test_motivbot_update_task(self, supabase_config, headers, cleanup_tasks):
        """Test actualizar tarea por HTTP"""
        # Crear tarea primero
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Task to Update HTTP - Cleanup",
            "p_description": "Original description - Will be deleted"
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        assert create_response.status_code == 200
        create_result = create_response.json()
        task_id = create_result['id']
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(task_id)
        
        # Actualizar la tarea
        update_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_update_task"
        update_payload = {
            "p_task_id": task_id,
            "p_title": "Updated Task HTTP - Cleanup",
            "p_description": "Updated description - Will be deleted",
            "p_status": "completed"
        }
        
        response = requests.post(update_url, headers=headers, json=update_payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert result['message'] == 'Task updated successfully'

        def test_motivbot_create_task_with_special_characters(self, supabase_config, headers, cleanup_tasks):
            """Test crear tarea con caracteres especiales"""
            special_title = "Tarea con émojis 🚀 y caracteres especiales: @#$%^&*() - Cleanup"
            
            create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
            create_payload = {
                "p_title": special_title,
                "p_description": "Descripción con ñ, tildes áéíóú y símbolos ©®™"
            }
            
            response = requests.post(create_url, headers=headers, json=create_payload)
            
            assert response.status_code == 200
            result = response.json()
            
            if result.get('success', False):
                cleanup_tasks(result['id'])
                assert 'id' in result
            else:
                # Si falla, verificar que el error sea claro
                assert 'message' in result

        def test_motivbot_search_tasks_case_insensitive(self, supabase_config, headers, cleanup_tasks):
            """Test búsqueda de tareas insensible a mayúsculas/minúsculas"""
            # Crear tarea con texto en mayúsculas
            create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
            create_payload = {
                "p_title": "SEARCH TEST UPPERCASE - Cleanup",
                "p_description": "Testing case insensitive search"
            }
            
            create_response = requests.post(create_url, headers=headers, json=create_payload)
            create_result = create_response.json()
            
            if not create_result.get('success', False):
                pytest.skip("Task creation failed")
            
            task_id = create_result['id']
            cleanup_tasks(task_id)
            
            # Buscar en minúsculas
            search_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_search_tasks"
            search_payload = {"p_search": "search test"}
            
            response = requests.post(search_url, headers=headers, json=search_payload)
            
            assert response.status_code == 200
            result = response.json()
            
            assert isinstance(result, list)
            
            # Verificar que encuentra la tarea
            task_ids = [task['id'] for task in result]
            assert task_id in task_ids, "La búsqueda debe ser insensible a mayúsculas/minúsculas"

        def test_motivbot_get_dashboard_structure_validation(self, supabase_config, headers):
            """Test validación exhaustiva de estructura del dashboard"""
            url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_dashboard"
            
            response = requests.post(url, headers=headers, json={})
            
            assert response.status_code == 200
            result = response.json()
            
            # Verificar estructura básica
            required_keys = ['tasks', 'conversations', 'completion_rate', 'active_tasks', 'tags']
            for key in required_keys:
                assert key in result, f"Missing key: {key}"
            
            # Verificar tipos de datos
            assert isinstance(result['tasks'], (int, dict)), "tasks debe ser int o dict"
            assert isinstance(result['conversations'], (int, dict)), "conversations debe ser int o dict"
            assert isinstance(result['completion_rate'], (int, float)), "completion_rate debe ser numérico"
            assert isinstance(result['active_tasks'], int), "active_tasks debe ser int"
            assert isinstance(result['tags'], dict), "tags debe ser dict"
            
            # Verificar estructura de tags
            if 'total_unique' in result['tags']:
                assert isinstance(result['tags']['total_unique'], int)
            if 'most_used' in result['tags']:
                assert isinstance(result['tags']['most_used'], list)
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        assert create_response.status_code == 200
        create_result = create_response.json()
        task_id = create_result['id']
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(task_id)
        
        # Actualizar la tarea
        update_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_update_task"
        update_payload = {
            "p_task_id": task_id,
            "p_title": "Updated Task HTTP - Cleanup",
            "p_description": "Updated description - Will be deleted",
            "p_status": "completed"
        }
        
        response = requests.post(update_url, headers=headers, json=update_payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert result['message'] == 'Task updated successfully'
        
    def test_motivbot_update_task_tags(self, supabase_config, headers, cleanup_tasks):
        """✅ NUEVO: Test actualizar tags de una tarea"""
        # Crear tarea
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Task for Tags Update - Cleanup",
            "p_tags": ["original", "tags"]
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        task_result = create_response.json()
        task_id = task_result['id']
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(task_id)
        
        # Actualizar tags
        update_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_update_task"
        update_payload = {
            "p_task_id": task_id,
            "p_tags": ["updated", "new-tags", "test"]
        }
        
        response = requests.post(update_url, headers=headers, json=update_payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert result['message'] == 'Task updated successfully'
        
    def test_motivbot_delete_task(self, supabase_config, headers):
        """Test eliminar tarea por HTTP - Este test hace su propio cleanup"""
        # Primero crear una tarea
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Task to Delete HTTP - Self Cleanup"
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        assert create_response.status_code == 200
        create_result = create_response.json()
        task_id = create_result['id']
        
        # Eliminar la tarea (auto-cleanup)
        delete_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_delete_task"
        delete_payload = {
            "p_task_id": task_id
        }
        
        response = requests.post(delete_url, headers=headers, json=delete_payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert result['message'] == 'Task deleted successfully'
        
    def test_motivbot_search_tasks(self, supabase_config, headers):
        """Test buscar tareas por HTTP"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_search_tasks"
        
        payload = {
            "p_search": "test"
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
    def test_motivbot_search_tasks_with_tags(self, supabase_config, headers, cleanup_tasks):
        """✅ NUEVO: Test buscar tareas incluyendo búsqueda en tags"""
        # Crear tarea con tag específico
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Task for Search - Cleanup",
            "p_tags": ["searchable-tag", "unique-search"]
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        task_result = create_response.json()
        task_id = task_result['id']
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(task_id)
        
        # Buscar por tag
        search_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_search_tasks"
        search_payload = {
            "p_search": "searchable-tag",
            "p_search_tags": True
        }
        
        response = requests.post(search_url, headers=headers, json=search_payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
        # Verificar que nuestra tarea esté en los resultados
        task_ids = [task['id'] for task in result]
        assert task_id in task_ids
        
    def test_motivbot_create_conversation(self, supabase_config, headers, cleanup_tasks):
        """Test crear conversación por HTTP"""
        # Primero crear una tarea
        create_task_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        task_payload = {
            "p_title": "Task for Conversation HTTP - Cleanup"
        }
        
        task_response = requests.post(create_task_url, headers=headers, json=task_payload)
        assert task_response.status_code == 200
        task_result = task_response.json()
        task_id = task_result['id']
        
        # 🧹 Agregar tarea para cleanup
        cleanup_tasks(task_id)
        
        # Crear conversación
        conv_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_conversation"
        conv_payload = {
            "p_task_id": task_id,
            "p_role": "user",
            "p_message": "Hello, this is a test message via HTTP - Will be deleted"
        }
        
        response = requests.post(conv_url, headers=headers, json=conv_payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert 'id' in result
        assert result['message'] == 'Conversation created successfully'
        
    def test_motivbot_get_conversations(self, supabase_config, headers):
        """Test obtener conversaciones por HTTP"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_conversations"
        
        payload = {
            "p_limit": 50
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
    def test_motivbot_get_conversations_by_task(self, supabase_config, headers, cleanup_tasks):
        """Test obtener conversaciones filtradas por tarea"""
        # Crear tarea primero
        create_task_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        task_payload = {"p_title": "Task for Conv Filter - Cleanup"}
        
        task_response = requests.post(create_task_url, headers=headers, json=task_payload)
        task_result = task_response.json()
        task_id = task_result['id']
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(task_id)
        
        # Obtener conversaciones de esa tarea
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_conversations"
        payload = {
            "p_task_id": task_id,
            "p_limit": 50
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)

# ✅ NUEVA CLASE: Tests para funciones relacionadas con tags
class TestMotivbotTagsFunctions:
    
    def test_motivbot_get_popular_tags(self, supabase_config, headers):
        """✅ NUEVO: Test obtener tags populares"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_popular_tags"
        
        payload = {
            "p_limit": 10
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
        # Si hay tags, verificar estructura
        if len(result) > 0:
            tag_item = result[0]
            assert 'tag' in tag_item
            assert 'count' in tag_item
            assert isinstance(tag_item['count'], int)
            
    def test_motivbot_get_popular_tags_empty(self, supabase_config, headers):
        """✅ NUEVO: Test obtener tags populares cuando no hay datos"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_popular_tags"
        
        response = requests.post(url, headers=headers, json={})
        
        assert response.status_code == 200
        result = response.json()
        
        # Siempre debe devolver una lista, aunque esté vacía
        assert isinstance(result, list)
        
    def test_motivbot_get_motivational_messages(self, supabase_config, headers):
        """✅ NUEVO: Test obtener mensajes motivacionales"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_motivational_messages"
        
        payload = {
            "p_limit": 5
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
        # Si hay mensajes, verificar estructura
        if len(result) > 0:
            message = result[0]
            assert 'id' in message
            assert 'mensaje' in message
            assert 'estado' in message
            assert 'tags' in message
            
    def test_motivbot_get_motivational_messages_by_tags(self, supabase_config, headers):
        """✅ NUEVO: Test obtener mensajes motivacionales por tags"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_motivational_messages"
        
        payload = {
            "p_tags": ["motivacional", "positivo"],
            "p_limit": 3
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
    def test_motivbot_get_motivational_messages_by_estado(self, supabase_config, headers):
        """✅ NUEVO: Test obtener mensajes motivacionales por estado emocional"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_motivational_messages"
        
        payload = {
            "p_estado": "happy",
            "p_limit": 5
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
        # Si hay mensajes, verificar que el estado coincida
        if len(result) > 0:
            for message in result:
                assert message['estado'] == 'happy'
                
    def test_motivbot_get_motivational_messages_by_task(self, supabase_config, headers, cleanup_tasks):
        """✅ NUEVO: Test obtener mensajes motivacionales para una tarea específica"""
        # Crear tarea con tags
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Task for Messages - Cleanup",
            "p_tags": ["trabajo", "importante"]
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        task_result = create_response.json()
        task_id = task_result['id']
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(task_id)
        
        # Obtener mensajes para esa tarea
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_motivational_messages"
        payload = {
            "p_task_id": task_id,
            "p_limit": 5
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)

# Tests de manejo de errores
class TestMotivbotErrorHandling:
    
    def test_invalid_supabase_url(self):
        """Test con URL de Supabase inválida"""
        headers = {
            'apikey': 'fake_key',
            'Authorization': 'Bearer fake_key',
            'Content-Type': 'application/json'
        }
        
        url = os.getenv('VITE_SUPABASE_URL', 'https://invalid.supabase.co') + '/rest/v1/rpc/motivbot_get_tasks'
        
        response = requests.post(url, headers=headers, json={})
        
        # Debería fallar la conexión
        assert response.status_code != 200
        
    def test_missing_auth_header(self, supabase_config):
        """Test sin headers de autenticación"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_tasks"
        
        # Sin headers de auth
        headers = {'Content-Type': 'application/json'}
        
        response = requests.post(url, headers=headers, json={})
        
        # Debería devolver error de autenticación
        assert response.status_code in [401, 403]
        
    def test_invalid_rpc_function(self, supabase_config, headers):
        """Test con función RPC que no existe"""
        url = f"{supabase_config['url']}/rest/v1/rpc/nonexistent_function"
        
        response = requests.post(url, headers=headers, json={})
        
        # Debería devolver error 404 o similar
        assert response.status_code == 404
        
    def test_motivbot_get_motivational_messages_invalid_task(self, supabase_config, headers):
        """✅ NUEVO: Test mensajes motivacionales con task_id inválido"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_motivational_messages"
        
        payload = {
            "p_task_id": 99999999,  # ID que no existe
            "p_limit": 5
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        # Puede devolver 200 con mensaje de error o lista vacía
        assert response.status_code == 200
        result = response.json()
        
        # Si devuelve error, verificar estructura
        if isinstance(result, dict) and 'success' in result:
            assert result['success'] is False
        else:
            # Si devuelve lista, puede estar vacía
            assert isinstance(result, list)
            
    def test_motivbot_update_task_invalid_id(self, supabase_config, headers):
        """✅ NUEVO: Test actualizar tarea con ID inválido"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_update_task"
        
        payload = {
            "p_task_id": 99999999,  # ID que no existe
            "p_title": "Updated Title"
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is False
        assert 'not found' in result['message'].lower()

# ✅ NUEVA CLASE: Tests de integración completa
class TestMotivbotIntegration:
    
    def test_complete_task_lifecycle_with_tags(self, supabase_config, headers, cleanup_tasks):
        """✅ NUEVO: Test ciclo completo de tarea con tags y mensajes"""
        
        # 1. Crear tarea con tags
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Integration Test Task - Cleanup",
            "p_description": "Complete lifecycle test",
            "p_priority": "high",
            "p_tags": ["test", "integration", "high-priority"]
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        assert create_response.status_code == 200
        create_result = create_response.json()
        task_id = create_result['id']
        
        # 🧹 Agregar para cleanup
        cleanup_tasks(task_id)
        
        # 2. Verificar que se creó con los tags correctos
        get_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_tasks"
        get_payload = {"p_tags": ["integration"], "p_limit": 50}
        
        get_response = requests.post(get_url, headers=headers, json=get_payload)
        assert get_response.status_code == 200
        tasks = get_response.json()
        
        task_ids = [task['id'] for task in tasks]
        assert task_id in task_ids
        
        # 3. Actualizar tags
        update_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_update_task"
        update_payload = {
            "p_task_id": task_id,
            "p_tags": ["updated", "integration", "completed"]
        }
        
        update_response = requests.post(update_url, headers=headers, json=update_payload)
        assert update_response.status_code == 200
        update_result = update_response.json()
        assert update_result['success'] is True
        
        # 4. Buscar por los nuevos tags
        search_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_search_tasks"
        search_payload = {
            "p_search": "updated",
            "p_search_tags": True
        }
        
        search_response = requests.post(search_url, headers=headers, json=search_payload)
        assert search_response.status_code == 200
        search_results = search_response.json()
        
        search_task_ids = [task['id'] for task in search_results]
        assert task_id in search_task_ids
        
        # 5. Obtener mensajes motivacionales para la tarea
        messages_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_motivational_messages"
        messages_payload = {
            "p_task_id": task_id,
            "p_limit": 3
        }
        
        messages_response = requests.post(messages_url, headers=headers, json=messages_payload)
        assert messages_response.status_code == 200
        messages_result = messages_response.json()
        
        # Debe devolver una lista (puede estar vacía si no hay mensajes)
        assert isinstance(messages_result, list)
        
        print(f"✅ Integration test completed successfully for task {task_id}")

# Test pipeline validation - PR #2 - Updated with Tags Support