import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, filter, map } from 'rxjs';
import { createClient, SupabaseClient, Session, User, processLock } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';

export type RolUsuario = 'ADMINISTRADOR' | 'MEDICO' | 'FARMACEUTICO' | 'PACIENTE';

export interface PerfilUsuario {
  id: string;
  email: string;
  nombre: string;
  rol: RolUsuario;
}

@Injectable({ providedIn: 'root' })
export class SupabaseService {
  private supabase: SupabaseClient;
  // undefined = aún no se consultó Supabase; null = no hay sesión activa
  private sessionSubject = new BehaviorSubject<Session | null | undefined>(undefined);
  session$: Observable<Session | null> = this.sessionSubject.asObservable().pipe(
    filter((s): s is Session | null => s !== undefined)
  );

  user$: Observable<PerfilUsuario | null> = this.session$.pipe(
    map(s => s ? this.perfilDeSession(s) : null)
  );

  role$: Observable<RolUsuario | null> = this.user$.pipe(
    map(u => u ? u.rol : null)
  );

  constructor() {
    this.supabase = createClient(environment.supabase.url, environment.supabase.anonKey, {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true,
        // processLock evita NavigatorLockAcquireTimeoutError cuando hay
        // varias pestanas o cuando el navegador (Brave/anti-fingerprint)
        // bloquea Navigator LockManager.
        lock: processLock
      }
    });

    this.supabase.auth.getSession().then(({ data }) => this.sessionSubject.next(data.session));
    this.supabase.auth.onAuthStateChange((_event, session) => this.sessionSubject.next(session));
  }

  async signIn(email: string, password: string): Promise<{ ok: boolean; error?: string }> {
    const { error } = await this.supabase.auth.signInWithPassword({ email, password });
    return error ? { ok: false, error: error.message } : { ok: true };
  }

  async signOut(): Promise<void> {
    await this.supabase.auth.signOut();
  }

  async getAccessToken(): Promise<string | null> {
    const { data } = await this.supabase.auth.getSession();
    return data.session?.access_token ?? null;
  }

  private perfilDeSession(session: Session): PerfilUsuario {
    const u: User = session.user;
    const rol = (u.app_metadata?.['role'] as RolUsuario)
      || (u.user_metadata?.['role'] as RolUsuario)
      || 'PACIENTE';
    return {
      id: u.id,
      email: u.email ?? '',
      nombre: (u.user_metadata?.['name'] as string) || u.email || 'Usuario',
      rol
    };
  }
}
