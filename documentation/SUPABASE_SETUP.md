# Puesta en marcha de MUSICAL BUDGET — Cicloramas Producciones

## Estado actual
El frontend ya inicializa el cliente de Supabase con la URL y la clave publicable. Eso confirma la configuración inicial, pero todavía no hay persistencia de datos ni inicio de sesión.

## Paso 1 — Crear la estructura de la base de datos
1. Abrí el proyecto de Supabase de MUSICAL BUDGET.
2. Entrá en **SQL Editor**.
3. Elegí **New query**.
4. Abrí el archivo [database/setup_cicloramas.sql](../database/setup_cicloramas.sql) en GitHub.
5. Copiá todo su contenido, pegalo en SQL Editor y presioná **Run**.
6. Esperá el resultado. Si aparece un error, no ejecutes otros scripts: copiá el mensaje y compartilo para corregirlo.

**Importante:** para esta instalación inicial usá únicamente `database/setup_cicloramas.sql`. No ejecutes `database/schema.sql` ni `database/migrations/001_core_security.sql`; son archivos de una arquitectura anterior y no forman parte de este procedimiento.

## Paso 2 — Verificar las tablas
En Supabase, abrí **Table Editor**. Deberían aparecer, entre otras:
- organizations
- organization_members
- productions
- budgets
- budget_items
- financial_movements
- suppliers
- exchange_rates
- audit_logs

Las tablas tienen Row Level Security (RLS) activado. No cargues datos reales todavía.

## Paso 3 — Próxima etapa: acceso de la administradora
Después de confirmar que el SQL se ejecutó sin errores, configuraremos el acceso por correo y contraseña. La primera cuenta administradora autenticada inicializará la organización Cicloramas Producciones mediante la función segura `bootstrap_cicloramas()`.

No compartas contraseñas, claves secretas ni credenciales de base de datos en el chat o en GitHub. La clave publicable del navegador no reemplaza las políticas RLS.

## Alcance de esta primera estructura
Incluye organizaciones y miembros, producciones, presupuestos e ítems, ingresos y gastos, proveedores, cotizaciones ARS/USD y una tabla de auditoría preparada. Los registros automáticos de auditoría, autenticación, pantallas CRUD y persistencia desde los formularios se implementarán y probarán en etapas siguientes.

**No usar todavía para información financiera, contractual o personal real.** Primero hay que completar el inicio de sesión, conectar los formularios y probar los permisos.
