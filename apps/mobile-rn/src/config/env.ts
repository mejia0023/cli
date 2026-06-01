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
};

export const env = {
  supabaseUrl: extra.supabaseUrl ?? '',
  supabaseAnonKey: extra.supabaseAnonKey ?? '',
  graphqlUrl: extra.graphqlUrl ?? 'http://localhost:8080/graphql',
  blockchainUrl: extra.blockchainUrl ?? 'http://localhost:3001',
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
