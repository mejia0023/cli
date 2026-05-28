import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { map, take } from 'rxjs';
import { RolUsuario, SupabaseService } from './supabase.service';

export const roleGuard: CanActivateFn = (route) => {
  const supabase = inject(SupabaseService);
  const router = inject(Router);
  const allowed = (route.data['roles'] as RolUsuario[]) ?? [];

  return supabase.user$.pipe(
    take(1),
    map(user => {
      if (!user) { router.navigate(['/login']); return false; }
      if (allowed.length === 0 || allowed.includes(user.rol)) return true;
      router.navigate(['/forbidden']);
      return false;
    })
  );
};
