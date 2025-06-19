-- Tabla principal para mensajes motivacionales con chibi
CREATE TABLE chibi_messages (
    id SERIAL PRIMARY KEY,
    mensaje TEXT NOT NULL,
    estado VARCHAR(50) NOT NULL, -- clave para imagen del chibi (ej: 'happy', 'excited', 'calm', 'energetic')
    tags TEXT[] NOT NULL, -- array de tags para filtrado
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimizar búsquedas
CREATE INDEX idx_chibi_messages_estado ON chibi_messages(estado);
CREATE INDEX idx_chibi_messages_tags ON chibi_messages USING GIN(tags);
CREATE INDEX idx_chibi_messages_created_at ON chibi_messages(created_at);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at
CREATE TRIGGER update_chibi_messages_updated_at 
    BEFORE UPDATE ON chibi_messages 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insertar algunos mensajes de ejemplo
INSERT INTO chibi_messages (mensaje, estado, tags) VALUES
('¡Hoy es un gran día para conquistar el mundo! 🌟', 'excited', ARRAY['motivacional', 'energia', 'positivo']),
('Respira profundo, todo va a estar bien 💙', 'calm', ARRAY['relajante', 'ansiedad', 'paciencia']),
('¡Eres más fuerte de lo que crees! 💪', 'happy', ARRAY['autoestima', 'fuerza', 'confianza']),
('Paso a paso, sin prisa pero sin pausa 🐢', 'peaceful', ARRAY['paciencia', 'progreso', 'constancia']);

-- Habilitar RLS (Row Level Security)
ALTER TABLE chibi_messages ENABLE ROW LEVEL SECURITY;

-- Política para permitir SELECT a usuarios anónimos
CREATE POLICY "Allow anonymous read access" ON chibi_messages
FOR SELECT 
TO anon 
USING (true);

-- Política para permitir INSERT a usuarios anónimos (opcional)
CREATE POLICY "Allow anonymous insert access" ON chibi_messages
FOR INSERT 
TO anon 
WITH CHECK (true);

-- Política para permitir UPDATE a usuarios anónimos (opcional)
CREATE POLICY "Allow anonymous update access" ON chibi_messages
FOR UPDATE 
TO anon 
USING (true) 
WITH CHECK (true);

-- Política para permitir DELETE a usuarios anónimos (opcional)
CREATE POLICY "Allow anonymous delete access" ON chibi_messages
FOR DELETE 
TO anon 
USING (true);

-- Grants explícitos para el rol anon
GRANT SELECT ON chibi_messages TO anon;
GRANT INSERT ON chibi_messages TO anon;
GRANT UPDATE ON chibi_messages TO anon;
GRANT DELETE ON chibi_messages TO anon;

-- Grant para usar la secuencia del ID
GRANT USAGE ON SEQUENCE chibi_messages_id_seq TO anon;

-- Crear función para obtener mensajes aleatorios
CREATE OR REPLACE FUNCTION get_random_chibi_messages(limit_count INTEGER DEFAULT 20)
RETURNS TABLE (
    id INTEGER,
    mensaje TEXT,
    estado VARCHAR(50),
    tags TEXT[],
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT cm.id, cm.mensaje, cm.estado, cm.tags, cm.created_at, cm.updated_at
    FROM chibi_messages cm
    ORDER BY RANDOM()
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Otorgar permisos de ejecución a usuarios anónimos
GRANT EXECUTE ON FUNCTION get_random_chibi_messages(INTEGER) TO anon;

-- También otorgar a usuarios autenticados por si acaso
GRANT EXECUTE ON FUNCTION get_random_chibi_messages(INTEGER) TO authenticated;
