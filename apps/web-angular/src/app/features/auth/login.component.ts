import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { SupabaseService } from '../../core/auth/supabase.service';
import { homePorRol } from '../../shared/layout/menu-items';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="login-wrapper">
      <div class="login-card">
        <h1>Clinica — Acceso</h1>
        <p class="subtitle">Ingresa con tu cuenta para continuar</p>

        <form (ngSubmit)="onSubmit()" autocomplete="on">
          <label>Email
            <input type="email" [(ngModel)]="email" name="email" required autofocus>
          </label>
          <label>Contraseña
            <input type="password" [(ngModel)]="password" name="password" required>
          </label>
          <button type="submit" [disabled]="loading">
            {{ loading ? 'Iniciando...' : 'Iniciar sesión' }}
          </button>
          <div class="error" *ngIf="error">{{ error }}</div>
        </form>

        <div class="hint">
          Usuarios de prueba: admin / medico / farma / paciente &#64;clinica.com
        </div>
      </div>
    </div>
  `,
  styles: [`
    .login-wrapper {
      min-height: 100vh;
      background: linear-gradient(135deg, #0f6e56 0%, #084030 100%);
      display: flex; align-items: center; justify-content: center;
      padding: 20px;
    }
    .login-card {
      background: white;
      border-radius: 12px;
      padding: 40px;
      width: 100%; max-width: 400px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    }
    h1 { margin: 0 0 8px 0; color: #0f6e56; font-size: 24px; }
    .subtitle { margin: 0 0 24px 0; color: #6b7280; font-size: 14px; }
    label { display: block; margin-bottom: 16px; font-size: 13px; font-weight: 500; color: #374151; }
    input {
      display: block; width: 100%; margin-top: 6px;
      padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 6px;
      font-size: 14px;
    }
    input:focus { outline: none; border-color: #0f6e56; box-shadow: 0 0 0 3px rgba(15,110,86,0.15); }
    button {
      width: 100%; padding: 12px; background: #0f6e56; color: white;
      border: none; border-radius: 6px; font-weight: 600; font-size: 14px;
      cursor: pointer; margin-top: 8px;
    }
    button:hover:not(:disabled) { background: #0d5e4a; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    .error {
      margin-top: 12px; padding: 10px; background: #fef2f2; color: #991b1b;
      border-radius: 6px; font-size: 13px;
    }
    .hint {
      margin-top: 24px; padding-top: 16px;
      border-top: 1px solid #e5e7eb;
      font-size: 12px; color: #6b7280; text-align: center;
    }
  `]
})
export class LoginComponent {
  email = '';
  password = '';
  loading = false;
  error = '';

  private supabase = inject(SupabaseService);
  private router = inject(Router);

  async onSubmit() {
    this.error = '';
    this.loading = true;
    const res = await this.supabase.signIn(this.email, this.password);
    this.loading = false;
    if (!res.ok) {
      this.error = res.error ?? 'Credenciales invalidas';
      return;
    }
    // Espera un tick para que session$ se actualice
    setTimeout(async () => {
      let perfilUsuario: any = null;
      const sub = this.supabase.user$.subscribe(u => perfilUsuario = u);
      sub.unsubscribe();
      const dest = perfilUsuario ? homePorRol(perfilUsuario.rol) : '/';
      this.router.navigateByUrl(dest);
    }, 200);
  }
}
