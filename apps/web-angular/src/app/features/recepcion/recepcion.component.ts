import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Apollo } from 'apollo-angular';
import { LIST_PACIENTES, CREATE_PACIENTE } from '../../core/graphql/queries';

@Component({
  selector: 'app-recepcion',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <h1 class="page-title">Recepción — Pacientes</h1>

    <div class="card">
      <div style="display: flex; gap: 12px; margin-bottom: 16px;">
        <input [(ngModel)]="q" (input)="buscar()" placeholder="Buscar por CI o nombre" style="flex:1; padding: 8px 12px; border:1px solid #d1d5db; border-radius: 6px;">
        <button (click)="toggleForm()" style="background: #0f6e56; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer;">
          <i class="pi pi-plus"></i> Nuevo paciente
        </button>
      </div>

      <form *ngIf="showForm" (ngSubmit)="crear()" class="form-grid">
        <input [(ngModel)]="form.ci" name="ci" placeholder="CI" required>
        <input [(ngModel)]="form.nombre" name="nombre" placeholder="Nombre" required>
        <input [(ngModel)]="form.apellido" name="apellido" placeholder="Apellido" required>
        <input [(ngModel)]="form.telefono" name="telefono" placeholder="Teléfono">
        <input [(ngModel)]="form.email" name="email" placeholder="Email" type="email">
        <input [(ngModel)]="form.fechaNacimiento" name="fechaNacimiento" placeholder="Fecha nacimiento" type="date">
        <button type="submit" style="grid-column: span 2; background: #0f6e56; color:white; border:none; padding: 10px; border-radius: 6px; cursor:pointer;">Guardar</button>
      </form>

      <table class="data-table">
        <thead>
          <tr><th>CI</th><th>Nombre</th><th>Apellido</th><th>Teléfono</th><th>Email</th></tr>
        </thead>
        <tbody>
          <tr *ngFor="let p of pacientes">
            <td>{{ p.ci }}</td><td>{{ p.nombre }}</td><td>{{ p.apellido }}</td>
            <td>{{ p.telefono }}</td><td>{{ p.email }}</td>
          </tr>
          <tr *ngIf="pacientes.length === 0"><td colspan="5" style="text-align:center; padding: 20px; color:#6b7280;">Sin resultados</td></tr>
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    .form-grid {
      display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; margin-bottom: 20px;
      padding: 16px; background: #f9fafb; border-radius: 6px;
    }
    .form-grid input { padding: 8px 10px; border: 1px solid #d1d5db; border-radius: 4px; }
    .data-table { width: 100%; border-collapse: collapse; }
    .data-table th, .data-table td { padding: 10px; border-bottom: 1px solid #e5e7eb; text-align: left; }
    .data-table th { background: #f3f4f6; font-weight: 600; font-size: 12px; text-transform: uppercase; color: #6b7280; }
  `]
})
export class RecepcionComponent implements OnInit {
  private apollo = inject(Apollo);
  pacientes: any[] = [];
  q = '';
  showForm = false;
  form = { ci: '', nombre: '', apellido: '', telefono: '', email: '', fechaNacimiento: '' };

  ngOnInit() { this.buscar(); }

  buscar() {
    this.apollo.query<any>({ query: LIST_PACIENTES, variables: { q: this.q || null }, fetchPolicy: 'network-only' })
      .subscribe({
        next: r => this.pacientes = r.data?.pacientes ?? [],
        error: e => console.error(e)
      });
  }

  toggleForm() { this.showForm = !this.showForm; }

  crear() {
    this.apollo.mutate<any>({ mutation: CREATE_PACIENTE, variables: { input: this.form } })
      .subscribe({
        next: () => {
          this.showForm = false;
          this.form = { ci: '', nombre: '', apellido: '', telefono: '', email: '', fechaNacimiento: '' };
          this.buscar();
        },
        error: e => alert('Error: ' + e.message)
      });
  }
}
