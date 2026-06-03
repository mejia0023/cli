import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Apollo } from 'apollo-angular';
import { take } from 'rxjs';
import { LIST_PACIENTES, MI_PACIENTE } from '../../core/graphql/queries';
import { SupabaseService } from '../../core/auth/supabase.service';
import { Ms2Service } from '../../core/services/ms2.service';

@Component({
  selector: 'app-documentos',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <h1 class="page-title">Documentos clínicos</h1>

    <div class="card" *ngIf="!esPaciente">
      <div class="field">
        <label>Paciente</label>
        <select [(ngModel)]="pacienteId" [ngModelOptions]="{standalone:true}" (change)="cargar()">
          <option [ngValue]="null">— Seleccionar —</option>
          <option *ngFor="let p of pacientes" [ngValue]="p.id">{{ p.ci }} · {{ p.nombre }} {{ p.apellido }}</option>
        </select>
      </div>
    </div>

    <div class="card" *ngIf="pacienteId">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <h3>Subir documento</h3>
        <button class="btn-primary" (click)="showForm=!showForm"><i class="pi pi-upload"></i> Subir</button>
      </div>
      <div *ngIf="showForm" class="form-block">
        <div class="field"><label>Archivo <span class="req">*</span></label>
          <input type="file" (change)="onFile($event)"></div>
        <div class="grid2">
          <div class="field"><label>Tipo</label><input [(ngModel)]="form.tipo" [ngModelOptions]="{standalone:true}" placeholder="estudio / receta / informe"></div>
          <div class="field"><label>Motivo (si es corrección)</label><input [(ngModel)]="form.motivo" [ngModelOptions]="{standalone:true}" placeholder="opcional"></div>
        </div>
        <p *ngIf="form.documentoId" class="meta">Subiendo NUEVA VERSIÓN del documento {{ form.documentoId }} · <a (click)="form.documentoId=null" class="link">cancelar</a></p>
        <div *ngIf="error" class="error-banner">{{ error }}</div>
        <button class="btn-primary" [disabled]="!file || subiendo" (click)="subir()">{{ subiendo ? 'Subiendo…' : 'Guardar versión' }}</button>
      </div>
    </div>

    <div class="card" *ngIf="pacienteId">
      <h3>Documentos vigentes</h3>
      <div *ngFor="let d of documentos" class="doc">
        <div style="display:flex; justify-content:space-between;">
          <div>
            <strong>{{ d.nombre_original }}</strong>
            <span class="badge">v{{ d.version }}</span>
            <span class="badge" *ngIf="d.tipo">{{ d.tipo }}</span>
            <span class="badge badge-green" *ngIf="d.blockchain_tx">on-chain</span>
            <span class="meta">{{ d.created_at | date:'short' }}</span>
          </div>
          <div>
            <button class="btn-link" (click)="descargar(d)">Descargar</button>
            <button class="btn-link" (click)="verVersiones(d)">Versiones</button>
            <button class="btn-link" (click)="verAuditoria(d)">Auditoría</button>
            <button class="btn-link" (click)="nuevaVersion(d)">+ versión</button>
          </div>
        </div>
        <div class="meta">hash: {{ d.hash_documento?.substring(0,24) }}…</div>

        <div *ngIf="versiones[d.documento_id]" class="sub">
          <strong>Versiones:</strong>
          <div *ngFor="let v of versiones[d.documento_id]">
            v{{ v.version }} · {{ v.created_at | date:'short' }} · por {{ v.editado_por }}
            <span *ngIf="v.vigente" class="badge badge-green">vigente</span>
            <a class="link" (click)="descargarVersion(d, v)">descargar</a>
          </div>
        </div>
        <div *ngIf="auditorias[d.documento_id]" class="sub">
          <strong>Auditoría:</strong>
          <div *ngFor="let a of auditorias[d.documento_id]">{{ a.timestamp | date:'short' }} · {{ a.accion }} · {{ a.rol }} ({{ a.usuario_uid }})</div>
        </div>
      </div>
      <p *ngIf="documentos.length === 0" class="empty">Sin documentos.</p>
    </div>

    <div class="card" *ngIf="esPaciente && !pacienteId">
      <p class="empty">No encontramos tu ficha de paciente vinculada a tu cuenta.</p>
    </div>
  `,
  styles: [`
    .field { display:flex; flex-direction:column; gap:4px; margin-bottom:12px; max-width:480px; }
    .field label { font-size:12px; font-weight:600; color:#374151; } .req { color:#dc2626; }
    .field input, .field select { padding:8px 10px; border:1px solid #d1d5db; border-radius:4px; font-size:14px; background:#fff; }
    .grid2 { display:grid; grid-template-columns:1fr 1fr; gap:10px; max-width:480px; }
    .form-block { padding:14px; background:#f9fafb; border-radius:6px; margin-top:10px; }
    .error-banner { padding:8px 12px; background:#fef2f2; color:#b91c1c; border:1px solid #fecaca; border-radius:4px; font-size:13px; margin:10px 0; }
    .doc { padding:12px; border:1px solid #e5e7eb; border-radius:6px; margin-bottom:10px; }
    .badge { font-size:10px; padding:2px 6px; border-radius:3px; font-weight:600; background:#e5e7eb; color:#374151; margin-left:6px; }
    .badge-green { background:#d1fae5; color:#065f46; }
    .meta { font-size:11px; color:#6b7280; margin-left:6px; }
    .btn-link { background:none; border:none; color:#0f6e56; cursor:pointer; text-decoration:underline; font-size:12px; margin-left:8px; }
    .link { color:#0f6e56; cursor:pointer; text-decoration:underline; }
    .sub { margin-top:8px; padding:8px; background:#f9fafb; border-radius:4px; font-size:12px; color:#374151; }
    .empty { color:#6b7280; text-align:center; padding:16px; }
  `]
})
export class DocumentosComponent implements OnInit {
  private apollo = inject(Apollo);
  private supabase = inject(SupabaseService);
  private ms2 = inject(Ms2Service);

  esPaciente = false;
  pacientes: any[] = [];
  pacienteId: string | null = null;
  documentos: any[] = [];
  versiones: Record<string, any[]> = {};
  auditorias: Record<string, any[]> = {};
  file: File | null = null;
  showForm = false;
  subiendo = false;
  error = '';
  form = { tipo: 'estudio', motivo: '', documentoId: null as string | null };

  ngOnInit() {
    this.supabase.role$.pipe(take(1)).subscribe(rol => {
      this.esPaciente = rol === 'PACIENTE';
      if (this.esPaciente) {
        this.apollo.query<any>({ query: MI_PACIENTE, fetchPolicy: 'network-only' }).subscribe({
          next: r => { this.pacienteId = r.data?.miPaciente?.id ?? null; if (this.pacienteId) this.cargar(); },
          error: () => {}
        });
      } else {
        this.apollo.query<any>({ query: LIST_PACIENTES, variables: { q: null } })
          .subscribe(r => this.pacientes = r.data?.pacientes ?? []);
      }
    });
  }

  onFile(ev: Event) {
    const input = ev.target as HTMLInputElement;
    this.file = input.files && input.files.length ? input.files[0] : null;
  }

  cargar() {
    this.versiones = {}; this.auditorias = {};
    if (!this.pacienteId) { this.documentos = []; return; }
    this.ms2.listarDocumentos(this.pacienteId).subscribe({
      next: r => this.documentos = r ?? [], error: () => this.documentos = []
    });
  }

  nuevaVersion(d: any) { this.form.documentoId = d.documento_id; this.showForm = true; }

  subir() {
    if (!this.file || !this.pacienteId) return;
    this.subiendo = true; this.error = '';
    const fd = new FormData();
    fd.append('archivo', this.file);
    fd.append('paciente_id', this.pacienteId);
    fd.append('tipo', this.form.tipo || 'estudio');
    if (this.form.motivo) fd.append('motivo_cambio', this.form.motivo);
    if (this.form.documentoId) fd.append('documento_id', this.form.documentoId);
    this.ms2.subirDocumento(fd).subscribe({
      next: () => {
        this.subiendo = false; this.showForm = false; this.file = null;
        this.form = { tipo: 'estudio', motivo: '', documentoId: null };
        this.cargar();
      },
      error: e => { this.subiendo = false; this.error = e?.error?.error || e.message || 'Error al subir'; }
    });
  }

  verVersiones(d: any) {
    this.ms2.versiones(d.documento_id).subscribe(r => this.versiones[d.documento_id] = r ?? []);
  }
  verAuditoria(d: any) {
    this.ms2.auditoria(d.documento_id).subscribe(r => this.auditorias[d.documento_id] = r ?? []);
  }
  descargar(d: any) { this.descargarVersion(d, d); }
  descargarVersion(d: any, v: any) {
    this.ms2.descargar(d.documento_id, String(v.version)).subscribe(blob => {
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = d.nombre_original || 'documento'; a.click();
      URL.revokeObjectURL(url);
    });
  }
}
