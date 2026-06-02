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
          <span class="badge">{{ f.estado }}</span>
        </div>
        <div style="font-size: 18px; font-weight: 700; color: #0f6e56;">Bs {{ f.total }}</div>
      </div>
      <ul>
        <li *ngFor="let d of f.detalles">{{ d.medicamento.nombre }} × {{ d.cantidad }} = Bs {{ d.subtotal }}</li>
      </ul>
    </div>
    <p *ngIf="facturas.length === 0" style="text-align: center; color: #6b7280; padding: 40px;">No tienes facturas registradas.</p>
  `,
  styles: [`
    .badge { background: #d1fae5; color: #065f46; padding: 2px 8px; border-radius: 3px; font-size: 11px; font-weight: 600; margin-left: 8px; }
  `]
})
export class MisFacturasComponent implements OnInit {
  private apollo = inject(Apollo);
  facturas: any[] = [];

  ngOnInit() {
    this.apollo.query<any>({ query: MIS_FACTURAS, fetchPolicy: 'network-only' })
      .subscribe({ next: r => this.facturas = r.data?.misFacturas ?? [], error: () => this.facturas = [] });
  }
}
