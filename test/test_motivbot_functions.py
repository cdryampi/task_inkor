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
        
    def test_motivbot_create_task(self, supabase_config, headers):
        """Test crear tarea por HTTP"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        
        payload = {
            "p_title": "Test Task HTTP",
            "p_description": "Test Description",
            "p_priority": "normal"
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert 'id' in result
        assert result['message'] == 'Task created successfully'
        
    def test_motivbot_get_tasks(self, supabase_config, headers):
        """Test obtener tareas por HTTP"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_get_tasks"
        
        response = requests.post(url, headers=headers, json={})
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
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
        
    def test_motivbot_create_task_validation(self, supabase_config, headers):
        """Test validación al crear tarea sin título"""
        url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        
        payload = {
            "p_title": None
        }
        
        response = requests.post(url, headers=headers, json=payload)
        
        # Puede ser 400 (bad request) o 200 con error en el JSON
        if response.status_code == 200:
            result = response.json()
            assert result['success'] is False
            assert 'Title is required' in result['message']
        else:
            assert response.status_code == 400
        
    def test_motivbot_update_task(self, supabase_config, headers):
        """Test actualizar tarea por HTTP"""
        # Primero crear una tarea
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Task to Update HTTP",
            "p_description": "Original description"
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        assert create_response.status_code == 200
        create_result = create_response.json()
        task_id = create_result['id']
        
        # Actualizar la tarea
        update_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_update_task"
        update_payload = {
            "p_task_id": task_id,
            "p_title": "Updated Task HTTP",
            "p_description": "Updated description",
            "p_status": "completed"
        }
        
        response = requests.post(update_url, headers=headers, json=update_payload)
        
        assert response.status_code == 200
        result = response.json()
        
        assert result['success'] is True
        assert result['message'] == 'Task updated successfully'
        
    def test_motivbot_delete_task(self, supabase_config, headers):
        """Test eliminar tarea por HTTP"""
        # Primero crear una tarea
        create_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        create_payload = {
            "p_title": "Task to Delete HTTP"
        }
        
        create_response = requests.post(create_url, headers=headers, json=create_payload)
        assert create_response.status_code == 200
        create_result = create_response.json()
        task_id = create_result['id']
        
        # Eliminar la tarea
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
        
    def test_motivbot_create_conversation(self, supabase_config, headers):
        """Test crear conversación por HTTP"""
        # Primero crear una tarea
        create_task_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        task_payload = {
            "p_title": "Task for Conversation HTTP"
        }
        
        task_response = requests.post(create_task_url, headers=headers, json=task_payload)
        assert task_response.status_code == 200
        task_result = task_response.json()
        task_id = task_result['id']
        
        # Crear conversación
        conv_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_conversation"
        conv_payload = {
            "p_task_id": task_id,
            "p_role": "user",
            "p_message": "Hello, this is a test message via HTTP"
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
        
        response = requests.post(url, headers=headers, json={})
        
        assert response.status_code == 200
        result = response.json()
        
        assert isinstance(result, list)
        
    def test_motivbot_get_conversations_by_task(self, supabase_config, headers):
        """Test obtener conversaciones filtradas por tarea"""
        # Crear tarea primero
        create_task_url = f"{supabase_config['url']}/rest/v1/rpc/motivbot_create_task"
        task_payload = {"p_title": "Task for Conv Filter"}
        
        task_response = requests.post(create_task_url, headers=headers, json=task_payload)
        task_result = task_response.json()
        task_id = task_result['id']
        
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