# Hoja de ruta de MUSICAL BUDGET

## Entrega 1 — Base visual y financiera
- [x] Estructura de navegación.
- [x] Dashboard preliminar.
- [x] Vistas iniciales de producciones y presupuestos.
- [x] Registro demostrativo de ingresos y gastos.
- [x] Flujo de caja separado por moneda.
- [x] Exportación CSV de datos demo.
- [x] Primer esquema relacional PostgreSQL.

## Entrega 2 — Organizaciones, usuarios y seguridad
- Crear proyecto Supabase y configurar variables de entorno.
- Implementar inicio y cierre de sesión.
- Crear organizaciones y alta de miembros por invitación.
- Definir permisos detallados por rol.
- Completar políticas RLS de lectura y escritura.
- Probar aislamiento entre organizaciones.
- Registrar altas, cambios, aprobaciones y anulaciones en auditoría.

## Entrega 3 — Producciones y presupuestos
- Ficha integral de producción, temporada, sala, fechas y responsables.
- Rubros y subrubros configurables para teatro musical.
- Ítems con cantidad, unidad, costo unitario, impuestos y subtotal.
- Versionado y comparación de presupuestos.
- Circuito de revisión y aprobación.
- Presupuesto original, vigente, comprometido, ejecutado y disponible.

## Entrega 4 — Administración financiera
- Gastos, órdenes de compra, comprobantes y pagos parciales.
- Ingresos, aportes, subsidios, coproducciones y ventas.
- Proveedores, datos fiscales y condiciones de pago.
- Flujo de caja previsto y real.
- Cuentas y medios de pago.
- Cotizaciones históricas ARS/USD documentadas.

## Entrega 5 — Operación teatral
- Personal artístico, técnico, creativo y administrativo.
- Honorarios, contratos, anticipos y liquidaciones.
- Boletería, entradas, cortesías, devoluciones y recaudación.
- Liquidaciones de salas, plataformas y coproductores.
- Giras, funciones y presupuestos por plaza.

## Entrega 6 — Dirección e inteligencia de gestión
- Rentabilidad por producción, temporada, sala y función.
- Punto de equilibrio y recuperación de inversión.
- Comparativo presupuesto vs. ejecución.
- Informes por período, rubro, proveedor y moneda.
- Exportación PDF, XLSX y CSV.
- Indicadores históricos multiempresa.

## Criterios obligatorios
- Cada registro multiempresa debe pertenecer a una organización.
- No sumar ARS y USD sin una conversión explícita y trazable.
- Registrar en auditoría las acciones sensibles.
- Nunca incluir claves privadas o service-role keys en el frontend.
- No usar datos reales hasta terminar autenticación, RLS y pruebas de aislamiento.
