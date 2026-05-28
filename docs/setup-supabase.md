# Setup de Supabase para autenticación

Supabase es la fuente única de identidad para los 3 microservicios (Alimbert, Javier, José). Todos validan el mismo JWT vía JWKS asimétrico.

## 1. Crear proyecto

1. Ir a https://supabase.com → New Project.
2. Nombre: `clinica-sw2`. Región: la más cercana. Password de DB: guardar en gestor.
3. Esperar provisión (~2 min).

## 2. Configurar Auth

1. **Auth → Providers → Email**: habilitar, deshabilitar confirmación de email para desarrollo (`Confirm email = OFF`).
2. **Auth → URL Configuration**: agregar `http://localhost:4200` y la URL final de producción en `Site URL` y `Redirect URLs`.

## 3. Crear 4 usuarios de prueba

En **Auth → Users → Add user → Create new user** (sin enviar invitación):

| Email | Password | Rol |
|---|---|---|
| `admin@clinica.com` | `Admin123!` | ADMINISTRADOR |
| `medico@clinica.com` | `Medico123!` | MEDICO |
| `farma@clinica.com` | `Farma123!` | FARMACEUTICO |
| `paciente@clinica.com` | `Paciente123!` | PACIENTE |

Para **cada usuario** creado, editar y poner en `raw_app_meta_data` (no en `raw_user_meta_data` — esa puede ser editada por el usuario desde el cliente):

```json
{ "role": "ADMINISTRADOR" }
```

> **Tip:** desde el SQL Editor de Supabase:
> ```sql
> UPDATE auth.users
> SET raw_app_meta_data = raw_app_meta_data || '{"role":"ADMINISTRADOR"}'::jsonb
> WHERE email = 'admin@clinica.com';
> ```

## 4. Copiar URL JWKS

`Project Settings → API` muestra:
- **Project URL**: `https://xxxxx.supabase.co`
- **anon public key**: para Angular.
- **service_role secret key**: NO usar en frontend, solo en jobs administrativos.

**JWKS endpoint** (calculado): `https://xxxxx.supabase.co/auth/v1/.well-known/jwks.json`.

Poner en `.env`:
```
SUPABASE_JWKS_URI=https://xxxxx.supabase.co/auth/v1/.well-known/jwks.json
```

## 5. Verificar token

1. Login en Angular con `admin@clinica.com`.
2. En DevTools Console: `(await supabase.auth.getSession()).data.session.access_token`.
3. Copiar el JWT, pegarlo en https://jwt.io.
4. Confirmar que `sub` está, `email` está, y `app_metadata.role` es `ADMINISTRADOR`.

Si `app_metadata.role` no aparece → el rol no se guardó bien en el paso 3. Re-ejecutar.

## 6. Coordinar con Javier y José

Cuando ellos se sumen, **comparten el mismo proyecto Supabase**. Cada uno configura su microservicio con la misma `SUPABASE_JWKS_URI`. No es necesario compartir secretos: JWKS es público.
