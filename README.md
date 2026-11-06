# MUSICAL BUDGET

Sistema de gestión financiera y presupuestaria para productoras, salas y compañías de teatro musical.

## Primera entrega — versión 0.1

Incluye una interfaz web inicial y un modelo de datos de referencia:
- Panel general con indicadores de ingresos, gastos y ejecución presupuestaria.
- Navegación por producciones, presupuestos, gastos, ingresos, flujo de caja, proveedores, informes y configuración.
- Registro local de movimientos financieros de demostración.
- Separación de importes en ARS y USD.
- Exportación de movimientos demo a CSV.
- Esquema inicial PostgreSQL para futura integración con Supabase.
- Diseño adaptable a escritorio y dispositivos móviles.

## Cómo abrir
Abrí `index.html` en un navegador o publicá el repositorio con GitHub Pages.

## Importante
Esta versión es un prototipo frontend. Los datos son ficticios y se almacenan temporalmente en memoria del navegador; se pierden al recargar. Todavía no hay autenticación, persistencia, aislamiento multiempresa efectivo ni permisos operativos. **No ingresar datos financieros, contractuales o personales reales.**

El archivo `database/schema.sql` es una base inicial que requiere revisión y pruebas antes de ejecutarse. Las políticas RLS habilitan lectura para miembros y dejan la escritura pendiente de la matriz definitiva de permisos por rol.

## Avance de backend — preparación de seguridad

Se agregó `database/migrations/001_core_security.sql` con políticas RLS iniciales, funciones auxiliares de membresía/roles, alta atómica de organizaciones y tabla de auditoría. La guía `documentation/SUPABASE_SETUP.md` explica cómo preparar el proyecto Supabase.

**Estado actual:** el frontend todavía no está conectado a Supabase. La migración debe probarse en un proyecto de desarrollo y someterse a revisión de permisos antes de usar información real. La tabla de auditoría todavía no registra automáticamente todos los cambios: eso requiere triggers/eventos adicionales.

## Arquitectura prevista
- Frontend web responsive.
- Supabase / PostgreSQL para autenticación y persistencia.
- Separación multiempresa con Row Level Security.
- Auditoría de acciones sensibles.
- Cotizaciones ARS/USD con fecha, fuente y responsable; sin conversiones automáticas opacas.

## Módulos previstos
Organizaciones; usuarios, roles y permisos; producciones y temporadas; presupuestos por rubros e ítems; gastos y pagos; ingresos y financiación; flujo de caja; proveedores y compras; personal, honorarios y contratos; boletería y liquidaciones; rentabilidad y punto de equilibrio; informes, estadísticas y auditoría.

Ver [Hoja de ruta](documentation/ROADMAP.md).
