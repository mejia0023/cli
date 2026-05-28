import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { map } from 'rxjs';
import { MENU } from './menu-items';
import { SupabaseService } from '../../core/auth/supabase.service';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <aside class="sidebar">
      <div class="brand">
        <i class="pi pi-heart-fill"></i>
        <span>Clinica</span>
      </div>
      <nav>
        <a *ngFor="let item of items$ | async"
           [routerLink]="item.route"
           routerLinkActive="active"
           class="nav-item">
          <i class="pi {{ item.icon }}"></i>
          <span>{{ item.label }}</span>
        </a>
      </nav>
      <div class="bottom" *ngIf="user$ | async as u">
        <div class="user-info">
          <div class="user-name">{{ u.nombre }}</div>
          <div class="user-role">{{ u.rol }}</div>
        </div>
        <button class="logout" (click)="logout()">
          <i class="pi pi-sign-out"></i> Salir
        </button>
      </div>
    </aside>
  `,
  styles: [`
    .sidebar {
      width: 240px;
      background: #0f6e56;
      color: #f5fbf8;
      display: flex;
      flex-direction: column;
      height: 100vh;
    }
    .brand {
      padding: 20px;
      font-size: 18px;
      font-weight: 700;
      border-bottom: 1px solid rgba(255,255,255,0.1);
      display: flex; align-items: center; gap: 10px;
    }
    nav { flex: 1; padding: 12px 0; overflow-y: auto; }
    .nav-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 10px 20px;
      color: #d6efe5;
      cursor: pointer;
      text-decoration: none;
      transition: background 0.2s;
    }
    .nav-item:hover { background: rgba(255,255,255,0.08); text-decoration: none; }
    .nav-item.active { background: rgba(255,255,255,0.15); color: white; font-weight: 600; }
    .nav-item i { width: 18px; text-align: center; }
    .bottom {
      padding: 16px 20px;
      border-top: 1px solid rgba(255,255,255,0.1);
    }
    .user-name { font-weight: 600; font-size: 13px; }
    .user-role { font-size: 11px; opacity: 0.7; text-transform: uppercase; letter-spacing: 0.5px; }
    .logout {
      margin-top: 12px;
      background: transparent;
      border: 1px solid rgba(255,255,255,0.2);
      color: #d6efe5;
      padding: 6px 12px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 12px;
      width: 100%;
      display: flex; align-items: center; justify-content: center; gap: 6px;
    }
    .logout:hover { background: rgba(255,255,255,0.1); }
  `]
})
export class SidebarComponent {
  private supabase = inject(SupabaseService);
  user$ = this.supabase.user$;
  items$ = this.supabase.role$.pipe(
    map(rol => rol ? MENU.filter(i => i.roles.includes(rol)) : [])
  );

  async logout() {
    await this.supabase.signOut();
    location.href = '/login';
  }
}
