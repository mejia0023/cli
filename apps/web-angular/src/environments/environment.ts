/**
 * Configuracion de DESARROLLO.
 *
 * IMPORTANTE: este archivo se versiona con placeholders. Antes de correr
 * `ng serve` reemplaza los valores marcados con <...> con los tuyos.
 *
 * Para no commitear tus credenciales reales por accidente, considera tambien:
 *   - Copiar este archivo a `environment.local.ts` (esta en .gitignore)
 *     e importarlo desde `main.ts` con un fileReplacement en angular.json.
 *   - O usar el patron "config.json" servido desde assets/ y cargarlo al boot.
 */
export const environment = {
  production: false,
  graphqlUrl: 'http://localhost:4000/graphql',
  ms2Url: 'http://localhost:8000',
  blockchainUrl: 'http://localhost:3001',
  supabase: {
    // Project URL: Project Settings -> API -> Project URL
    url: '<YOUR_SUPABASE_URL>',
    // Publishable key (NO la service_role secret): Project Settings -> API Keys -> Publishable
    anonKey: '<YOUR_SUPABASE_PUBLISHABLE_KEY>'
  }
};
