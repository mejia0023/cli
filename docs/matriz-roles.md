# Matriz de roles y permisos

Sistema integral de clínica. 4 roles del sistema completo, todos respetados aunque su UI viva en otros equipos del grupo.

## Roles

| Rol | Descripción | Quién implementa su UI |
|---|---|---|
| **ADMINISTRADOR** | Gestiona usuarios, ve BI, opera caja/recepción/inventario, verifica recetas | Alimbert (Angular web) |
| **MEDICO** | Emite recetas (dispara blockchain), verifica integridad de recetas, consulta historia clínica | José (Angular web médicos) — usa ms-gestion para recetas |
| **FARMACEUTICO** | Caja, inventario, dispensación, verificar recetas | Alimbert (Angular web) |
| **PACIENTE** | Consulta sus facturas y recetas, agenda citas (con Javier) | Javier (app móvil RN) — usa ms-gestion para sus facturas/recetas |

## Permisos por dominio (en ms-gestion GraphQL)

| Operación | ADMIN | MEDICO | FARMA | PACIENTE |
|---|:-:|:-:|:-:|:-:|
| `medicamentos` (listar) | ✓ | ✓ | ✓ | — |
| `crearMedicamento` / `actualizarMedicamento` | ✓ | — | ✓ | — |
| `registrarEntradaLote` / `ajustarStock` | ✓ | — | ✓ | — |
| `inventarioCritico` | ✓ | — | ✓ | — |
| `crearFactura` / `anularFactura` | ✓ | — | ✓ | — |
| `facturas` (todas) | ✓ | — | ✓ | — |
| `misFacturas` (propias) | — | — | — | ✓ |
| `emitirReceta` | — | ✓ | — | — |
| `verificarReceta` | ✓ | ✓ | ✓ | — |
| `misRecetas` (propias) | — | — | — | ✓ |
| `bi*` (todos los reportes) | ✓ | — | — | — |
| CRUD usuarios | ✓ | — | — | — |

## Principio de seguridad

**Frontend oculta (UX); backend bloquea (seguridad real).**

- En Angular: sidebar dinámico filtra items por rol → mejora UX.
- En Spring: cada resolver tiene `@PreAuthorize` que valida rol del JWT → es la única defensa real.
- Para operaciones de paciente sobre sus propios datos: filtrar por `pacienteId == authentication.principal.pacienteId` en el service, no solo en `@PreAuthorize`.
