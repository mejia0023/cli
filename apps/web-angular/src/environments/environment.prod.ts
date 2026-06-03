/**
 * Configuracion de PRODUCCION.
 *
 * Reemplaza placeholders con los valores reales antes de `ng build --prod`.
 * Considera inyectar estos valores en build time desde CI/CD (GitHub Actions,
 * Azure DevOps, etc.) en vez de hardcodearlos en este archivo.
 */
export const environment = {
  production: true,
  graphqlUrl: '<YOUR_GATEWAY_GRAPHQL_URL>',           // ej: https://gateway.<tudominio>.com/graphql
  ms2Url: '<YOUR_MS2_URL>',                           // ej: https://ms-diagnosticos.<tudominio>.com
  blockchainUrl: '<YOUR_BLOCKCHAIN_URL>',             // ej: https://ms-blockchain.<tudominio>.com
  supabase: {
    url: '<YOUR_SUPABASE_URL>',
    anonKey: '<YOUR_SUPABASE_PUBLISHABLE_KEY>'
  }
};
