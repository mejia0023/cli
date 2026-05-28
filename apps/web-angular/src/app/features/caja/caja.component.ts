import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Apollo } from 'apollo-angular';
import { LIST_MEDICAMENTOS, LIST_PACIENTES, CREATE_FACTURA } from '../../core/graphql/queries';

interface CartItem {
  medicamentoId: string;
  nombre: string;
  precio: number;
  cantidad: number;
  controlado: boolean;
  requiereReceta: boolean;
  recetaId?: string;
}

@Component({
  selector: 'app-caja',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <h1 class="page-title">Caja — Punto de venta</h1>

    <div class="grid">
      <div class="card products">
        <h3>Medicamentos</h3>
        <input [(ngModel)]="q" (input)="buscarMed()" placeholder="Buscar..." class="search">
        <div class="med-list">
          <div *ngFor="let m of medicamentos" class="med-card" (click)="agregar(m)">
            <div>
              <div class="med-name">{{ m.nombre }}</div>
              <div class="med-meta">
                <span *ngIf="m.requiereReceta" class="badge badge-amber">Receta</span>
                <span *ngIf="m.controlado" class="badge badge-red">Controlado</span>
              </div>
            </div>
            <div class="med-price">Bs {{ m.precioVenta }}</div>
          </div>
        </div>
      </div>

      <div class="card cart">
        <h3>Carrito</h3>
        <div *ngFor="let it of carrito; let i = index" class="cart-item">
          <div style="flex:1;">
            <div>{{ it.nombre }}</div>
            <input *ngIf="it.requiereReceta" [(ngModel)]="it.recetaId" name="r{{i}}" placeholder="ID Receta" style="font-size: 11px; margin-top: 4px; padding: 4px;">
          </div>
          <input type="number" [(ngModel)]="it.cantidad" name="c{{i}}" min="1" style="width: 60px;">
          <span>{{ (it.precio * it.cantidad).toFixed(2) }}</span>
          <button (click)="quitar(i)" class="btn-icon"><i class="pi pi-times"></i></button>
        </div>

        <div class="total-row">
          <strong>Total: Bs {{ total().toFixed(2) }}</strong>
        </div>

        <label>Paciente (opcional)
          <select [(ngModel)]="pacienteId" name="paciente">
            <option [ngValue]="null">— Cliente sin registro —</option>
            <option *ngFor="let p of pacientes" [ngValue]="p.id">{{ p.ci }} · {{ p.nombre }} {{ p.apellido }}</option>
          </select>
        </label>

        <label>Método de pago
          <select [(ngModel)]="metodoPago" name="metodo">
            <option value="EFECTIVO">Efectivo</option>
            <option value="TARJETA">Tarjeta</option>
            <option value="TRANSFERENCIA">Transferencia</option>
            <option value="QR">QR</option>
          </select>
        </label>

        <button (click)="facturar()" [disabled]="carrito.length === 0 || facturando" class="btn-primary">
          {{ facturando ? 'Facturando...' : 'Facturar' }}
        </button>

        <div *ngIf="ultimaFactura" class="success-msg">
          Factura {{ ultimaFactura.numero }} — Bs {{ ultimaFactura.total }}
        </div>
      </div>
    </div>
  `,
  styles: [`
    .grid { display: grid; grid-template-columns: 1fr 340px; gap: 16px; }
    .products .search { width: 100%; padding: 8px; border: 1px solid #d1d5db; border-radius: 4px; margin-bottom: 12px; }
    .med-list { max-height: 600px; overflow-y: auto; }
    .med-card {
      display: flex; justify-content: space-between; align-items: center;
      padding: 12px; border: 1px solid #e5e7eb; border-radius: 6px;
      margin-bottom: 8px; cursor: pointer; transition: background 0.15s;
    }
    .med-card:hover { background: #f0fdf4; border-color: #5dcaa5; }
    .med-name { font-weight: 600; }
    .med-meta { margin-top: 4px; display: flex; gap: 6px; }
    .badge { font-size: 10px; padding: 2px 6px; border-radius: 3px; font-weight: 600; }
    .badge-amber { background: #fef3c7; color: #92400e; }
    .badge-red { background: #fee2e2; color: #991b1b; }
    .med-price { font-weight: 700; color: #0f6e56; }
    .cart { position: sticky; top: 0; }
    .cart-item {
      display: flex; align-items: center; gap: 8px;
      padding: 8px 0; border-bottom: 1px solid #f3f4f6;
    }
    .cart-item input[type=number] { padding: 4px; border: 1px solid #d1d5db; border-radius: 4px; }
    .btn-icon { background: none; border: none; color: #a32d2d; cursor: pointer; }
    .total-row { margin: 16px 0; padding: 12px; background: #f0fdf4; border-radius: 4px; text-align: right; font-size: 16px; }
    label { display: block; margin-bottom: 12px; font-size: 12px; color: #6b7280; }
    label select { width: 100%; padding: 8px; border: 1px solid #d1d5db; border-radius: 4px; margin-top: 4px; font-size: 14px; }
    .btn-primary { width: 100%; padding: 12px; background: #0f6e56; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 600; }
    .btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }
    .success-msg { margin-top: 12px; padding: 8px; background: #d1fae5; color: #065f46; border-radius: 4px; font-size: 13px; }
  `]
})
export class CajaComponent implements OnInit {
  private apollo = inject(Apollo);
  medicamentos: any[] = [];
  pacientes: any[] = [];
  carrito: CartItem[] = [];
  q = '';
  pacienteId: string | null = null;
  metodoPago = 'EFECTIVO';
  facturando = false;
  ultimaFactura: any = null;

  ngOnInit() {
    this.buscarMed();
    this.apollo.query<any>({ query: LIST_PACIENTES, variables: { q: null } })
      .subscribe(r => this.pacientes = r.data?.pacientes ?? []);
  }

  buscarMed() {
    this.apollo.query<any>({ query: LIST_MEDICAMENTOS, variables: { q: this.q || null, activo: true }, fetchPolicy: 'network-only' })
      .subscribe(r => this.medicamentos = r.data?.medicamentos ?? []);
  }

  agregar(m: any) {
    const exist = this.carrito.find(it => it.medicamentoId === m.id);
    if (exist) { exist.cantidad++; return; }
    this.carrito.push({
      medicamentoId: m.id, nombre: m.nombre,
      precio: Number(m.precioVenta), cantidad: 1,
      controlado: m.controlado, requiereReceta: m.requiereReceta
    });
  }

  quitar(i: number) { this.carrito.splice(i, 1); }

  total(): number {
    return this.carrito.reduce((s, it) => s + it.precio * it.cantidad, 0);
  }

  facturar() {
    this.facturando = true;
    const input = {
      pacienteId: this.pacienteId,
      metodoPago: this.metodoPago,
      descuento: 0,
      items: this.carrito.map(it => ({
        medicamentoId: it.medicamentoId,
        cantidad: it.cantidad,
        recetaId: it.recetaId || null
      }))
    };
    this.apollo.mutate<any>({ mutation: CREATE_FACTURA, variables: { input } }).subscribe({
      next: r => {
        this.facturando = false;
        this.ultimaFactura = r.data?.crearFactura;
        this.carrito = [];
        this.buscarMed();
      },
      error: e => { this.facturando = false; alert('Error: ' + e.message); }
    });
  }
}
