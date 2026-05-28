import { ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideAnimations } from '@angular/platform-browser/animations';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { Apollo, APOLLO_OPTIONS } from 'apollo-angular';
import { HttpLink } from 'apollo-angular/http';
import { InMemoryCache } from '@apollo/client/core';
import { setContext } from '@apollo/client/link/context';

import { APP_ROUTES } from './app.routes';
import { SupabaseService } from './core/auth/supabase.service';
import { environment } from '../environments/environment';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(APP_ROUTES, withComponentInputBinding()),
    provideAnimations(),
    provideHttpClient(),
    SupabaseService,
    {
      provide: APOLLO_OPTIONS,
      useFactory(httpLink: HttpLink, supabase: SupabaseService) {
        const http = httpLink.create({ uri: environment.graphqlUrl });
        const authLink = setContext(async () => {
          const token = await supabase.getAccessToken();
          return token ? { headers: { Authorization: `Bearer ${token}` } } : {};
        });
        return {
          link: authLink.concat(http),
          cache: new InMemoryCache({
            typePolicies: {
              Medicamento: { keyFields: ['id'] },
              Paciente: { keyFields: ['id'] },
              Factura: { keyFields: ['id'] },
              Receta: { keyFields: ['id'] }
            }
          }),
          defaultOptions: {
            watchQuery: { fetchPolicy: 'cache-and-network', errorPolicy: 'all' },
            query: { fetchPolicy: 'network-only', errorPolicy: 'all' },
            mutate: { errorPolicy: 'all' }
          }
        };
      },
      deps: [HttpLink, SupabaseService]
    },
    Apollo
  ]
};
