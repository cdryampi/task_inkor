import os
import pytest
from supabase import create_client

# Retrieve Supabase credentials from environment variables
SUPABASE_URL = os.getenv("SUPABASE_URL") or os.getenv("VITE_SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY") or os.getenv("VITE_SUPABASE_ANON_KEY")

@pytest.fixture(scope="session")
def client():
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        pytest.skip("Supabase credentials not configured")
    return create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

def test_task_lifecycle(client):
    # Create a task
    res = client.rpc('motivbot_create_task', {'p_title': 'Pytest Task'}).execute()
    data = res.data
    assert data['success'] is True
    task_id = data['id']

    # Update the task status
    update = client.rpc('motivbot_update_task', {
        'p_task_id': task_id,
        'p_status': 'completed'
    }).execute()
    assert update.data['success'] is True

    # Retrieve tasks filtered by status
    tasks_res = client.rpc('motivbot_get_tasks', {
        'p_status': 'completed',
        'p_limit': 50
    }).execute()
    tasks = tasks_res.data
    assert isinstance(tasks, list)
    assert any(t['id'] == task_id for t in tasks)

    # Delete the task
    delete_res = client.rpc('motivbot_delete_task', {'p_task_id': task_id}).execute()
    assert delete_res.data['success'] is True

def test_conversation_lifecycle(client):
    # Create a task for the conversation
    task = client.rpc('motivbot_create_task', {'p_title': 'Conversation Task'}).execute()
    task_id = task.data['id']

    # Create a conversation linked to the task
    conv = client.rpc('motivbot_create_conversation', {
        'p_task_id': task_id,
        'p_role': 'user',
        'p_message': 'Hello from pytest'
    }).execute()
    conv_data = conv.data
    assert conv_data['success'] is True
    conv_id = conv_data['id']

    # Update feedback on the conversation
    feedback = client.rpc('motivbot_update_conversation_feedback', {
        'p_conversation_id': conv_id,
        'p_user_is_grateful': True
    }).execute()
    assert feedback.data['success'] is True

    # Fetch conversations for the task
    convs = client.rpc('motivbot_get_conversations', {'p_task_id': task_id}).execute()
    conv_list = convs.data
    assert isinstance(conv_list, list)
    assert any(c['id'] == conv_id for c in conv_list)

    # Clean up conversation and task
    del_conv = client.rpc('motivbot_delete_conversation', {'p_conversation_id': conv_id}).execute()
    assert del_conv.data['success'] is True
    client.rpc('motivbot_delete_task', {'p_task_id': task_id}).execute()

def test_get_dashboard(client):
    dashboard = client.rpc('motivbot_get_dashboard', {}).execute()
    data = dashboard.data
    assert 'tasks' in data
    assert 'conversations' in data
