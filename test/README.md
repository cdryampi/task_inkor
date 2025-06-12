## Pruebas de las funciones del MotivBot
Estas funciones están pensadas para ser ejecutadas en un entorno de pruebas, como pytest.
Especialmente para garantizar que funcione el bot de GPT actions y se pueda utilizar correctamente.
### Ejemplo de uso
```python
    pytest .\test_motivbot_functions.py -v
```

### Funciones de prueba
- `test_motivbot_functions.py`: Pruebas de las funciones del MotivBot.

```bash
(.venv) PS C:\codigo\backend-curso-inkor\task_inkor\test> pytest .\test_motivbot_functions.py -v
=================================================== test session starts ===================================================
platform win32 -- Python 3.12.6, pytest-8.4.0, pluggy-1.6.0 -- C:\codigo\backend-curso-inkor\task_inkor\.venv\Scripts\python.exe
cachedir: .pytest_cache
rootdir: C:\codigo\backend-curso-inkor\task_inkor\test
collected 14 items

test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_get_dashboard PASSED                             [  7%]
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_create_task PASSED                               [ 14%]
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_get_tasks PASSED                                 [ 21%]
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_get_tasks_with_filters PASSED                    [ 28%]
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_create_task_validation PASSED                    [ 35%]
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_update_task PASSED                               [ 42%]
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_delete_task PASSED                               [ 50%]
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_get_tasks PASSED                                 [ 21%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_get_tasks_with_filters PASSED                    [ 28%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_create_task_validation PASSED                    [ 35%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_update_task PASSED                               [ 42%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_delete_task PASSED                               [ 50%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_get_tasks_with_filters PASSED                    [ 28%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_create_task_validation PASSED                    [ 35%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_update_task PASSED                               [ 42%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_delete_task PASSED                               [ 50%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_create_task_validation PASSED                    [ 35%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_update_task PASSED                               [ 42%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_delete_task PASSED                               [ 50%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_update_task PASSED                               [ 42%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_delete_task PASSED                               [ 50%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_delete_task PASSED                               [ 50%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_search_tasks PASSED                              [ 57%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_create_conversation PASSED                       [ 64%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_create_conversation PASSED                       [ 64%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_get_conversations PASSED                         [ 71%] 
test_motivbot_functions.py::TestMotivbotRPCFunctions::test_motivbot_get_conversations_by_task PASSED                 [ 78%] 
test_motivbot_functions.py::TestMotivbotErrorHandling::test_invalid_supabase_url PASSED                              [ 85%] 
test_motivbot_functions.py::TestMotivbotErrorHandling::test_missing_auth_header PASSED                               [ 92%] 
test_motivbot_functions.py::TestMotivbotErrorHandling::test_invalid_rpc_function PASSED                              [100%] 

=================================================== 14 passed in 2.54s ====================================================
```
### Requisitos
- Python 3.8 o superior.
- pytest instalado en el entorno virtual.
- Acceso a una instancia de Supabase configurada para el MotivBot.
### Notas
- Asegúrate de que las variables de entorno necesarias estén configuradas correctamente antes de ejecutar las pruebas.
- Las pruebas están diseñadas para ejecutarse en un entorno aislado, por lo que no deben afectar a los datos reales del MotivBot.
- Las pruebas se pueden ejecutar por la pipeline de github actions, para garantizar que las funciones del MotivBot funcionen correctamente.