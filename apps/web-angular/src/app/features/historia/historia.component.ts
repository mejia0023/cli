import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Apollo } from 'apollo-angular';
import { HISTORIA_POR_PACIENTE, LIST_PACIENTES } from '../../core/graphql/queries';

@Component({
  selector: 'app-historia',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <h1 class="page-title">Historia clínica</h1>

    <div class="card">
      <div class="field">
        <label>Paciente</label>
        <select [(ngModel)]="pacienteId" [ngModelOptions]="{standalone:true}" (change)="cargar()">
          <option [ngValue]="null">— Seleccionar paciente —</option>
          <option *ngFor="let p of pacientes" [ngValue]="p.id">{{ p.ci }} · {{ p.nombre }} {{ p.apellido }}</option>
        </select>
      </div>
    </div>

    <div class="card" *ngIf="pacienteId && historia">
      <h3>Historia <span class="badge">{{ historia.estado }}</span></h3>
      <p class="meta">Apertura: {{ historia.fechaApertura | date:'short' }} · {{ historia.episodios?.length || 0 }} episodio(s)</p>
      <div *ngFor="let e of historia.episodios" class="epi">
        <div class="meta">{{ e.fecha | date:'short' }} · médico {{ e.medicoUid }}</div>
        <p *ngIf="e.motivoConsulta"><strong>Motivo:</strong> {{ e.motivoConsulta }}</p>
        <p *ngIf="e.evolucion"><strong>Evolución:</strong> {{ e.evolucion }}</p>
        <p *ngIf="e.diagnosticoTexto"><strong>Diagnóstico:</strong> {{ e.diagnosticoTexto }}</p>
      </div>
      <p *ngIf="(historia.episodios?.length || 0) === 0" class="empty">Sin episodios registrados.</p>
    </div>
    <div class="card" *ngIf="pacienteId && !historia && consultado">
      <p class="empty">Este paciente aún no tiene historia clínica abierta.</p>
    </div>
  `,
  styles: [`
    .field { display:flex; flex-direction:column; gap:4px; max-width:480px; }
    .field label { font-size:12px; font-weight:600; color:#374151; }
    .field select { padding:8px 10px; border:1px solid #d1d5db; border-radius:4px; font-size:14px; background:#fff; }
    .meta { font-size:12px; color:#6b7280; }
    .badge { font-size:10px; padding:2px 6px; border-radius:3px; font-weight:600; background:#d1fae5; color:#065f46; margin-left:6px; }
    .epi { border-left:3px solid #0f6e56; padding:8px 12px; margin:10px 0; background:#f9fafb; border-radius:0 6px 6px 0; }
    .epi p { margin:4px 0; font-size:13px; color:#374151; }
    .empty { color:#6b7280; text-align:center; padding:16px; }
  `]
})
export class HistoriaComponent implements OnInit {
  private apollo = inject(Apollo);
  pacientes: any[] = [];
  pacienteId: string | null = null;
  historia: any = null;
  consultado = false;

  ngOnInit() {
    this.apollo.query<any>({ query: LIST_PACIENTES, variables: { q: null } })
      .subscribe(r => this.pacientes = r.data?.pacientes ?? []);
  }

  cargar() {
    this.historia = null; this.consultado = false;
    if (!this.pacienteId) return;
    this.apollo.query<any>({ query: HISTORIA_POR_PACIENTE, variables: { pacienteId: this.pacienteId }, fetchPolicy: 'network-only' })
      .subscribe({
        next: r => { this.historia = r.data?.historiaPorPaciente ?? null; this.consultado = true; },
        error: () => { this.historia = null; this.consultado = true; }
      });
  }
}
