import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { map, take } from 'rxjs';
import { SupabaseService } from './supabase.service';

export const authGuard: CanActivateFn = () => {
  const supabase = inject(SupabaseService);
  const router = inject(Router);
  return supabase.session$.pipe(
    take(1),
    map(session => {
      if (session) return true;
      router.navigate(['/login']);
      return false;
    })
  );
};
