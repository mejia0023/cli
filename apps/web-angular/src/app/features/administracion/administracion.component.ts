import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Apollo } from 'apollo-angular';
import { LIST_USUARIOS, LIST_PROVEEDORES, LIST_CATEGORIAS } from '../../core/graphql/queries';

@Component({
  selector: 'app-administracion',
  standalone: true,
  imports: [CommonModule],
  template: `
    <h1 class="page-title">Administración</h1>

    <div class="card">
      <h3>Usuarios</h3>
      <table class="data-table">
        <thead><tr><th>Nombre</th><th>Email</th><th>Rol</th><th>Estado</th></tr></thead>
        <tbody>
          <tr *ngFor="let u of usuarios">
            <td>{{ u.nombre }}</td><td>{{ u.email }}</td>
            <td><span class="badge">{{ u.rol }}</span></td>
            <td>{{ u.activo ? '✓' : '—' }}</td>
          </tr>
          <tr *ngIf="usuarios.length === 0"><td colspan="4" style="text-align:center; padding: 20px; color:#6b7280;">Sin usuarios — se crearán al primer login (lazy provisioning).</td></tr>
        </tbody>
      </table>
    </div>

    <div class="card">
      <h3>Categorías</h3>
      <ul class="chip-list">
        <li *ngFor="let c of categorias">{{ c.nombre }}</li>
      </ul>
    </div>

    <div class="card">
      <h3>Proveedores</h3>
      <table class="data-table">
        <thead><tr><th>Nombre</th><th>NIT</th><th>Teléfono</th><th>Email</th><th>Activo</th></tr></thead>
        <tbody>
          <tr *ngFor="let p of proveedores">
            <td>{{ p.nombre }}</td><td>{{ p.nit }}</td><td>{{ p.telefono }}</td>
            <td>{{ p.email }}</td><td>{{ p.activo ? '✓' : '—' }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    .data-table { width: 100%; border-collapse: collapse; }
    .data-table th, .data-table td { padding: 10px; border-bottom: 1px solid #e5e7eb; text-align: left; }
    .data-table th { background: #f3f4f6; font-size: 12px; text-transform: uppercase; color: #6b7280; }
    .badge { background: #5dcaa5; color: white; padding: 2px 8px; border-radius: 3px; font-size: 11px; font-weight: 600; }
    .chip-list { list-style: none; padding: 0; display: flex; flex-wrap: wrap; gap: 8px; }
    .chip-list li { background: #f0fdf4; padding: 6px 12px; border-radius: 14px; font-size: 13px; }
  `]
})
export class AdministracionComponent implements OnInit {
  private apollo = inject(Apollo);
  usuarios: any[] = [];
  categorias: any[] = [];
  proveedores: any[] = [];

  ngOnInit() {
    this.apollo.query<any>({ query: LIST_USUARIOS, fetchPolicy: 'network-only' })
      .subscribe({ next: r => this.usuarios = r.data?.usuarios ?? [], error: () => this.usuarios = [] });
    this.apollo.query<any>({ query: LIST_CATEGORIAS, fetchPolicy: 'network-only' })
      .subscribe(r => this.categorias = r.data?.categorias ?? []);
    this.apollo.query<any>({ query: LIST_PROVEEDORES, fetchPolicy: 'network-only' })
      .subscribe(r => this.proveedores = r.data?.proveedores ?? []);
  }
}
