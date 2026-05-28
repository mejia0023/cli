import { Component, OnInit, inject } from '@angular/core';
import { Router } from '@angular/router';
import { take } from 'rxjs';
import { SupabaseService } from '../../core/auth/supabase.service';
import { homePorRol } from '../../shared/layout/menu-items';

@Component({
  selector: 'app-home-redirect',
  standalone: true,
  template: `<p>Redirigiendo…</p>`
})
export class HomeRedirectComponent implements OnInit {
  private supabase = inject(SupabaseService);
  private router = inject(Router);

  ngOnInit() {
    this.supabase.user$.pipe(take(1)).subscribe(u => {
      if (u) this.router.navigateByUrl(homePorRol(u.rol));
      else this.router.navigate(['/login']);
    });
  }
}
