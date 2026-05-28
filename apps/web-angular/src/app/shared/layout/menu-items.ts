import { RolUsuario } from '../../core/auth/supabase.service';

export interface MenuItem {
  label: string;
  icon: string;
  route: string;
  roles: RolUsuario[];
}

export const MENU: MenuItem[] = [
  { label: 'Recepción',      icon: 'pi-users',         route: '/recepcion',     roles: ['ADMINISTRADOR', 'FARMACEUTICO'] },
  { label: 'Caja',           icon: 'pi-shopping-cart', route: '/caja',          roles: ['ADMINISTRADOR', 'FARMACEUTICO'] },
  { label: 'Inventario',     icon: 'pi-box',           route: '/inventario',    roles: ['ADMINISTRADOR', 'FARMACEUTICO'] },
  { label: 'Administración', icon: 'pi-cog',           route: '/administracion',roles: ['ADMINISTRADOR'] },
  { label: 'Dashboard BI',   icon: 'pi-chart-bar',     route: '/dashboard',     roles: ['ADMINISTRADOR'] },
  { label: 'Mis recetas',    icon: 'pi-file-edit',     route: '/mis-recetas',   roles: ['MEDICO'] },
  { label: 'Mis facturas',   icon: 'pi-receipt',       route: '/mis-facturas',  roles: ['PACIENTE'] }
];

export function homePorRol(rol: RolUsuario): string {
  switch (rol) {
    case 'ADMINISTRADOR': return '/dashboard';
    case 'FARMACEUTICO':  return '/caja';
    case 'MEDICO':        return '/mis-recetas';
    case 'PACIENTE':      return '/mis-facturas';
  }
}
