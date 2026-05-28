# web-angular — Frontend Angular 17

SPA standalone que consume el GraphQL de ms-gestion y los servicios de Supabase Auth.

## Stack

- **Angular 17** (standalone components, lazy loading por feature)
- **Apollo Angular** + Apollo Client 3 con `setContext` async para inyectar JWT
- **Supabase JS** para login y manejo de sesión
- **PrimeNG** (tema lara-light-blue) + PrimeIcons
- **Chart.js** + **ng2-charts** para el Dashboard BI

## Setup local

```powershell
cd apps\web-angular

# Configurar src/environments/environment.ts con la URL de tu proyecto Supabase + anon key
npm install
npm start
# Abre http://localhost:4200
```

## Estructura

```
src/app/
├── app.component.ts        (root, solo <router-outlet>)
├── app.config.ts           (bootstrap standalone con Apollo + Supabase)
├── app.routes.ts           (rutas con authGuard y roleGuard funcionales)
├── core/
│   ├── auth/
│   │   ├── supabase.service.ts   (session$, user$, role$ observables)
│   │   ├── auth.guard.ts          (functional CanActivateFn)
│   │   └── role.guard.ts          (lee route.data.roles[])
│   └── graphql/queries.ts         (todas las queries y mutations en un solo archivo)
├── shared/layout/
│   ├── main-layout.component.ts   (sidebar + router-outlet)
│   ├── sidebar.component.ts       (filtra MENU por rol del usuario)
│   └── menu-items.ts              (MENU declarativo + homePorRol)
└── features/
    ├── auth/login + home-redirect
    ├── forbidden
    ├── recepcion           (ADMIN + FARMA)
    ├── caja                (ADMIN + FARMA)
    ├── inventario          (ADMIN + FARMA)
    ├── administracion      (ADMIN)
    ├── dashboard-bi        (ADMIN, 4 paneles Chart.js)
    ├── mis-recetas         (MEDICO)
    └── mis-facturas        (PACIENTE)
```

## Acceso por rol

| Rol | Home | Items en sidebar |
|---|---|---|
| ADMINISTRADOR | `/dashboard` | Recepción, Caja, Inventario, Administración, Dashboard BI |
| FARMACEUTICO | `/caja` | Recepción, Caja, Inventario |
| MEDICO | `/mis-recetas` | Mis recetas |
| PACIENTE | `/mis-facturas` | Mis facturas |

El backend valida con `@PreAuthorize` independientemente del menú del frontend.
