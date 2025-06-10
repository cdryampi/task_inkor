-- 1. Crear el tipo ENUM (Supabase usa PostgreSQL, y ENUM debe definirse previamente)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
        CREATE TYPE task_status AS ENUM ('pending', 'completed');
    END IF;
END$$;

-- 2. Crear la tabla
CREATE TABLE IF NOT EXISTS public.Task (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status task_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Crear la función para actualizar `updated_at`
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Crear el trigger
DROP TRIGGER IF EXISTS update_updated_at_trigger ON public.Task;

CREATE TRIGGER update_updated_at_trigger
BEFORE UPDATE ON public.Task
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 5. Habilitar RLS
ALTER TABLE public.Task ENABLE ROW LEVEL SECURITY;

-- 6. Crear políticas de seguridad
-- Permitir SELECT
DROP POLICY IF EXISTS "select_policy" ON public.Task;
CREATE POLICY "select_policy"
ON public.Task
FOR SELECT
TO anon, authenticated
USING (true);

-- Permitir INSERT
DROP POLICY IF EXISTS "insert_policy" ON public.Task;
CREATE POLICY "insert_policy"
ON public.Task
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Permitir UPDATE
DROP POLICY IF EXISTS "update_policy" ON public.Task;
CREATE POLICY "update_policy"
ON public.Task
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- Permitir DELETE
DROP POLICY IF EXISTS "delete_policy" ON public.Task;
CREATE POLICY "delete_policy"
ON public.Task
FOR DELETE
TO anon, authenticated
USING (true);

-- 7. Insertar datos de prueba
INSERT INTO public.Task (title, description, status) VALUES
('Completar proyecto Vue', 'Terminar la aplicación de tareas con Supabase', 'pending'),
('Estudiar PostgreSQL', 'Revisar documentación de RLS y políticas', 'pending'),
('Hacer ejercicio', 'Rutina de 30 minutos', 'completed'),
('Leer libro técnico', 'Continuar con el capítulo 5', 'pending');
