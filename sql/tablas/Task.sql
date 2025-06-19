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


-- Añadir campos de fecha y prioridad a la tabla task
ALTER TABLE task 
ADD COLUMN IF NOT EXISTS due_date DATE,
ADD COLUMN IF NOT EXISTS due_time TIME,
ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'medium', 'high'));

-- Insertar algunas tareas de ejemplo con fechas
INSERT INTO task (title, description, status, due_date, due_time, priority) VALUES
('Reunión con equipo', 'Planificación del sprint', 'pending', CURRENT_DATE, '10:00:00', 'high'),
('Revisar código', 'Pull request del proyecto X', 'pending', CURRENT_DATE + INTERVAL '1 day', '14:30:00', 'medium'),
('Completar documentación', 'Actualizar README del proyecto', 'pending', CURRENT_DATE + INTERVAL '2 days', '16:00:00', 'normal'),
('Llamada con cliente', 'Seguimiento del proyecto', 'completed', CURRENT_DATE - INTERVAL '1 day', '11:00:00', 'high');

-- Agregar más valores al ENUM task_status
ALTER TYPE task_status ADD VALUE IF NOT EXISTS 'in-progress';
ALTER TYPE task_status ADD VALUE IF NOT EXISTS 'on-hold';
ALTER TYPE task_status ADD VALUE IF NOT EXISTS 'cancelled';

-- Verificar los valores actuales del ENUM
SELECT enumlabel FROM pg_enum WHERE enumtypid = (
    SELECT oid FROM pg_type WHERE typname = 'task_status'
) ORDER BY enumsortorder;

-- Agregar columnas faltantes a la tabla task si no existen
ALTER TABLE public.task 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.task 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Crear trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_task_updated_at ON public.task;
CREATE TRIGGER update_task_updated_at
    BEFORE UPDATE ON public.task
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Agregar columna tags como array de texto
-- 1. Crear el tipo ENUM (Supabase usa PostgreSQL, y ENUM debe definirse previamente)
-- Agregar columna tags a la tabla existente
ALTER TABLE public.task 
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- Crear índice para búsquedas en tags
CREATE INDEX IF NOT EXISTS idx_task_tags ON public.task USING GIN(tags);
