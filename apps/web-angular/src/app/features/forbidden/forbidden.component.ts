import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-forbidden',
  standalone: true,
  imports: [RouterModule],
  template: `
    <div style="padding: 80px 40px; text-align: center;">
      <i class="pi pi-lock" style="font-size: 64px; color: #a32d2d;"></i>
      <h1 style="margin-top: 16px;">Acceso denegado</h1>
      <p>Tu rol no tiene permisos para esta sección.</p>
      <a routerLink="/">Volver al inicio</a>
    </div>
  `
})
export class ForbiddenComponent {}
