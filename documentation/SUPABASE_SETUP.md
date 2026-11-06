# Puesta en marcha del backend de MUSICAL BUDGET

## Qué se incorpora
- Migración SQL de seguridad multiempresa con Row Level Security (RLS).
- Alta atómica de organizaciones: crea la organización y asigna como propietario al usuario autenticado.
- Matriz inicial de lectura y escritura por rol.
- Registro de auditoría con lectura restringida y sin edición/borrado desde el cliente.

## Paso 1 — Crear el proyecto Supabase
1. Crear un proyecto nuevo de Supabase para MUSICAL BUDGET.
2. Guardar la contraseña de base de datos en un gestor seguro.
3. En Authentication, habilitar Email.
4. Configurar la URL publicada de GitHub Pages como Site URL y agregarla a Redirect URLs.
5. No compartir claves privadas ni subirlas a GitHub.

## Paso 2 — Ejecutar el esquema en orden
1. Abrir SQL Editor en Supabase.
2. Ejecutar primero database/schema.sql.
3. Ejecutar después database/migrations/001_core_security.sql.
4. Revisar que ambas ejecuciones finalicen sin errores.

La migración está diseñada para el esquema inicial del repositorio. Probarla primero en un proyecto vacío/de desarrollo, nunca sobre una base con información real.

## Paso 3 — Obtener configuración pública
En Project Settings → API, copiar Project URL y Publishable key (o anon key heredada).
La clave publicable puede estar en el frontend únicamente porque RLS debe proteger todas las tablas. Nunca usar service_role, claves secretas ni la contraseña de base de datos en JavaScript, HTML o GitHub.

## Paso 4 — Validación de seguridad
Crear dos usuarios de prueba y dos organizaciones distintas. Verificar que cada usuario solo vea su organización, que una sesión anónima no lea datos, que el rol de consulta no pueda modificar movimientos y que ningún administrador pueda apropiarse del rol owner.

## Estado
Esta etapa prepara la base de datos y sus políticas. Todavía no conecta la interfaz web con Supabase ni convierte el prototipo en una aplicación lista para producción. La conexión de login, sesión, formularios y consultas es la siguiente entrega.