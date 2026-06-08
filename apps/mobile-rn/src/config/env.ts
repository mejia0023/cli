import Constants from 'expo-constants';

/**
 * Lee la configuracion desde app.json -> expo.extra.
 * Tambien tolera valores undefined para desarrollo (fallback a localhost).
 */
const extra = (Constants.expoConfig?.extra ?? {}) as {
  supabaseUrl?: string;
  supabaseAnonKey?: string;
  graphqlUrl?: string;
  blockchainUrl?: string;
  diagnosticosUrl?: string;
};

// Host desde el que Expo sirvio el bundle: en modo LAN es la IP de tu PC
// (la del QR), en modo --localhost es 127.0.0.1 (con tuneles adb reverse).
// Asi gateway, IA y blockchain siguen SOLOS a Metro, sin tocar IPs nunca.
// Si defines las URLs en app.json -> extra, esas mandan (override manual).
const devHost = (Constants.expoConfig?.hostUri ?? 'localhost:8081').split(':')[0];

export const env = {
  supabaseUrl: extra.supabaseUrl ?? '',
  supabaseAnonKey: extra.supabaseAnonKey ?? '',
  graphqlUrl: extra.graphqlUrl ?? `http://${devHost}:4000/graphql`,
  blockchainUrl: extra.blockchainUrl ?? `http://${devHost}:3001`,
  diagnosticosUrl: extra.diagnosticosUrl ?? `http://${devHost}:8000`,
};

export function assertEnvReady() {
  const missing: string[] = [];
  if (!env.supabaseUrl || env.supabaseUrl.startsWith('<')) missing.push('supabaseUrl');
  if (!env.supabaseAnonKey || env.supabaseAnonKey.startsWith('<')) missing.push('supabaseAnonKey');
  if (missing.length > 0) {
    console.warn(
      '[env] Configuracion incompleta. Edita app.json -> expo.extra: faltan ' +
        missing.join(', ')
    );
  }
}
