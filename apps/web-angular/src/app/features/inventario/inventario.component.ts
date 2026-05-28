import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Apollo } from 'apollo-angular';
import { LIST_MEDICAMENTOS, CREATE_MEDICAMENTO, LIST_CATEGORIAS, LIST_LOTES, REGISTRAR_LOTE, LIST_PROVEEDORES } from '../../core/graphql/queries';

@Component({
  selector: 'app-inventario',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <h1 class="page-title">Inventario</h1>

    <div class="card">
      <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
        <h3>Medicamentos</h3>
        <button (click)="showFormMed = !showFormMed" class="btn-primary">
          <i class="pi pi-plus"></i> Nuevo medicamento
        </button>
      </div>

      <form *ngIf="showFormMed" (ngSubmit)="crearMed()" class="form-grid">
        <input [(ngModel)]="formMed.nombre" name="nombre" placeholder="Nombre" required>
        <select [(ngModel)]="formMed.categoriaId" name="categoria">
          <option [ngValue]="null">— Sin categoría —</option>
          <option *ngFor="let c of categorias" [ngValue]="c.id">{{ c.nombre }}</option>
        </select>
        <input [(ngModel)]="formMed.precioVenta" name="precio" type="number" step="0.01" placeholder="Precio venta" required>
        <input [(ngModel)]="formMed.stockMinimo" name="stockMin" type="number" placeholder="Stock mínimo">
        <label class="check"><input type="checkbox" [(ngModel)]="formMed.requiereReceta" name="rr"> Requiere receta</label>
        <label class="check"><input type="checkbox" [(ngModel)]="formMed.controlado" name="ctrl"> Controlado (blockchain)</label>
        <textarea [(ngModel)]="formMed.descripcion" name="desc" placeholder="Descripción" style="grid-column: span 2;"></textarea>
        <button type="submit" class="btn-primary" style="grid-column: span 2;">Guardar</button>
      </form>

      <table class="data-table">
        <thead>
          <tr><th>Nombre</th><th>Categoría</th><th>Precio</th><th>Stock mín</th><th>Flags</th><th></th></tr>
        </thead>
        <tbody>
          <tr *ngFor="let m of medicamentos">
            <td>{{ m.nombre }}</td>
            <td>{{ m.categoria?.nombre || '—' }}</td>
            <td>Bs {{ m.precioVenta }}</td>
            <td>{{ m.stockMinimo }}</td>
            <td>
              <span *ngIf="m.requiereReceta" class="badge badge-amber">Receta</span>
              <span *ngIf="m.controlado" class="badge badge-red">Controlado</span>
            </td>
            <td>
              <button (click)="toggleLotes(m)" class="btn-link">
                {{ medSeleccionado === m.id ? 'Ocultar lotes' : 'Ver lotes' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <div *ngIf="medSeleccionado" class="lotes-panel">
        <div style="display:flex; justify-content: space-between; align-items: center;">
          <h4>Lotes</h4>
          <button (click)="showFormLote = !showFormLote" class="btn-secondary">
            <i class="pi pi-plus"></i> Registrar entrada
          </button>
        </div>

        <form *ngIf="showFormLote" (ngSubmit)="registrarLote()" class="form-grid">
          <input [(ngModel)]="formLote.codigoLote" name="codigo" placeholder="Código lote" required>
          <select [(ngModel)]="formLote.proveedorId" name="prov">
            <option [ngValue]="null">— Sin proveedor —</option>
            <option *ngFor="let p of proveedores" [ngValue]="p.id">{{ p.nombre }}</option>
          </select>
          <input [(ngModel)]="formLote.fechaVencimiento" name="venc" type="date" required>
          <input [(ngModel)]="formLote.cantidad" name="cant" type="number" min="1" placeholder="Cantidad" required>
          <input [(ngModel)]="formLote.precioCompra" name="pc" type="number" step="0.01" placeholder="Precio compra" required>
          <button type="submit" class="btn-primary">Registrar</button>
        </form>

        <table class="data-table">
          <thead><tr><th>Código</th><th>Vence</th><th>Stock</th><th>Precio compra</th><th>Proveedor</th></tr></thead>
          <tbody>
            <tr *ngFor="let l of lotes">
              <td>{{ l.codigoLote }}</td>
              <td>{{ l.fechaVencimiento }}</td>
              <td>{{ l.cantidadActual }}</td>
              <td>Bs {{ l.precioCompra }}</td>
              <td>{{ l.proveedor?.nombre || '—' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  `,
  styles: [`
    .form-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; padding: 16px; background: #f9fafb; border-radius: 6px; margin-bottom: 16px; }
    .form-grid input, .form-grid select, .form-grid textarea { padding: 8px; border: 1px solid #d1d5db; border-radius: 4px; }
    .check { display: flex; align-items: center; gap: 6px; font-size: 13px; }
    .data-table { width: 100%; border-collapse: collapse; }
    .data-table th, .data-table td { padding: 10px; border-bottom: 1px solid #e5e7eb; text-align: left; }
    .data-table th { background: #f3f4f6; font-size: 12px; text-transform: uppercase; color: #6b7280; }
    .badge { font-size: 10px; padding: 2px 6px; border-radius: 3px; font-weight: 600; margin-right: 4px; }
    .badge-amber { background: #fef3c7; color: #92400e; }
    .badge-red { background: #fee2e2; color: #991b1b; }
    .btn-primary { background: #0f6e56; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; }
    .btn-secondary { background: white; color: #0f6e56; border: 1px solid #0f6e56; padding: 6px 12px; border-radius: 6px; cursor: pointer; }
    .btn-link { background: none; border: none; color: #0f6e56; cursor: pointer; text-decoration: underline; }
    .lotes-panel { margin-top: 20px; padding: 16px; background: #f0fdf4; border-radius: 6px; }
  `]
})
export class InventarioComponent implements OnInit {
  private apollo = inject(Apollo);
  medicamentos: any[] = [];
  categorias: any[] = [];
  proveedores: any[] = [];
  lotes: any[] = [];
  medSeleccionado: string | null = null;
  showFormMed = false;
  showFormLote = false;
  formMed = { nombre: '', descripcion: '', categoriaId: null as number | null, precioVenta: 0, requiereReceta: false, controlado: false, stockMinimo: 0 };
  formLote = { codigoLote: '', proveedorId: null as string | null, fechaVencimiento: '', cantidad: 1, precioCompra: 0 };

  ngOnInit() {
    this.cargar();
    this.apollo.query<any>({ query: LIST_CATEGORIAS }).subscribe(r => this.categorias = r.data?.categorias ?? []);
    this.apollo.query<any>({ query: LIST_PROVEEDORES }).subscribe(r => this.proveedores = r.data?.proveedores ?? []);
  }

  cargar() {
    this.apollo.query<any>({ query: LIST_MEDICAMENTOS, variables: { q: null, activo: null }, fetchPolicy: 'network-only' })
      .subscribe(r => this.medicamentos = r.data?.medicamentos ?? []);
  }

  crearMed() {
    this.apollo.mutate<any>({ mutation: CREATE_MEDICAMENTO, variables: { input: this.formMed } })
      .subscribe({
        next: () => { this.showFormMed = false; this.cargar(); },
        error: e => alert('Error: ' + e.message)
      });
  }

  toggleLotes(m: any) {
    if (this.medSeleccionado === m.id) { this.medSeleccionado = null; this.lotes = []; return; }
    this.medSeleccionado = m.id;
    this.apollo.query<any>({ query: LIST_LOTES, variables: { medicamentoId: m.id }, fetchPolicy: 'network-only' })
      .subscribe(r => this.lotes = r.data?.lotesByMedicamento ?? []);
  }

  registrarLote() {
    if (!this.medSeleccionado) return;
    this.apollo.mutate<any>({
      mutation: REGISTRAR_LOTE,
      variables: { input: { medicamentoId: this.medSeleccionado, ...this.formLote } }
    }).subscribe({
      next: () => {
        this.showFormLote = false;
        this.toggleLotes({ id: this.medSeleccionado }); this.toggleLotes({ id: this.medSeleccionado });
      },
      error: e => alert('Error: ' + e.message)
    });
  }
}
