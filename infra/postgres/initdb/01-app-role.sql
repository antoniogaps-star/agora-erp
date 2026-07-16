-- Rol de aplicación NO superusuario, para que Row-Level Security aísle de verdad.
-- Se ejecuta una sola vez al inicializar el contenedor de Postgres (como el usuario
-- dueño 'agora'). Credenciales SOLO de desarrollo — en producción, gestionar el rol y
-- su contraseña con un gestor de secretos, fuera de este archivo.

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'agora_app') THEN
        CREATE ROLE agora_app LOGIN PASSWORD 'agora_app';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE agora TO agora_app;
GRANT USAGE ON SCHEMA public TO agora_app;

-- Las tablas las crea 'agora' (dueño) al correr las migraciones DESPUÉS de este script;
-- estos privilegios por defecto hacen que agora_app reciba DML sobre ellas automáticamente.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO agora_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO agora_app;
