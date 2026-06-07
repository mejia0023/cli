import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Apollo, gql } from 'apollo-angular';

const MIS_FACTURAS = gql`
  query MisFacturas {
    misFacturas {
      id numero fecha total metodoPago estado
      detalles { medicamento { id nombre } cantidad subtotal }
    }
  }
`;

const CREAR_CHECKOUT = gql`
  mutation CrearCheckoutFactura($facturaId: UUID!) {
    crearCheckoutFactura(facturaId: $facturaId)
  }
`;

@Component({
  selector: 'app-mis-facturas',
  standalone: true,
  imports: [CommonModule],
  template: `
    <h1 class="page-title">Mis facturas</h1>
    <div *ngFor="let f of facturas" class="card">
      <div style="display: flex; justify-content: space-between;">
        <div>
          <strong>{{ f.numero }}</strong>
          <span style="margin-left: 12px; color: #6b7280;">{{ f.fecha | date:'short' }}</span>
          <span class="badge" [class.badge-pend]="f.estado !== 'PAGADA'">{{ f.estado }}</span>
        </div>
        <div style="font-size: 18px; font-weight: 700; color: #0f6e56;">Bs {{ f.total }}</div>
      </div>
      <button *ngIf="f.estado === 'PENDIENTE'" class="btn-pagar" (click)="pagar(f)" [disabled]="pagandoId === f.id">
        {{ pagandoId === f.id ? 'Abriendo pago…' : '💳 Pagar en línea' }}
      </button>
      <ul>
        <li *ngFor="let d of f.detalles">{{ d.medicamento.nombre }} × {{ d.cantidad }} = Bs {{ d.subtotal }}</li>
      </ul>
    </div>
    <p *ngIf="facturas.length === 0" style="text-align: center; color: #6b7280; padding: 40px;">No tienes facturas registradas.</p>
  `,
  styles: [`
    .badge { background: #d1fae5; color: #065f46; padding: 2px 8px; border-radius: 3px; font-size: 11px; font-weight: 600; margin-left: 8px; }
    .badge-pend { background: #e5e7eb; color: #374151; }
    .btn-pagar { margin-top: 8px; background: #0f6e56; color: #fff; border: none; border-radius: 6px; padding: 8px 14px; font-weight: 600; cursor: pointer; }
    .btn-pagar:disabled { opacity: .6; cursor: default; }
  `]
})
export class MisFacturasComponent implements OnInit {
  private apollo = inject(Apollo);
  facturas: any[] = [];
  pagandoId: string | null = null;

  ngOnInit() {
    this.apollo.query<any>({ query: MIS_FACTURAS, fetchPolicy: 'network-only' })
      .subscribe({ next: r => this.facturas = r.data?.misFacturas ?? [], error: () => this.facturas = [] });
  }

  pagar(f: any) {
    this.pagandoId = f.id;
    this.apollo.mutate<any>({ mutation: CREAR_CHECKOUT, variables: { facturaId: f.id } })
      .subscribe({
        next: r => {
          this.pagandoId = null;
          const url = r.data?.crearCheckoutFactura;
          if (url) { window.location.href = url; }
        },
        error: e => {
          this.pagandoId = null;
          alert('No se pudo iniciar el pago: ' + (e?.message ?? e));
        }
      });
  }
}
