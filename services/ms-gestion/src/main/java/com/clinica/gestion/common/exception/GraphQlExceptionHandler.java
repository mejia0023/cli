package com.clinica.gestion.common.exception;

import graphql.GraphQLError;
import graphql.GraphqlErrorBuilder;
import graphql.schema.DataFetchingEnvironment;
import org.springframework.graphql.execution.DataFetcherExceptionResolverAdapter;
import org.springframework.graphql.execution.ErrorType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Component;

@Component
public class GraphQlExceptionHandler extends DataFetcherExceptionResolverAdapter {

    @Override
    protected GraphQLError resolveToSingleError(Throwable ex, DataFetchingEnvironment env) {
        if (ex instanceof NotFoundException) {
            return build(ex, env, ErrorType.NOT_FOUND);
        }
        if (ex instanceof BusinessException) {
            return build(ex, env, ErrorType.BAD_REQUEST);
        }
        if (ex instanceof AccessDeniedException) {
            return build(ex, env, ErrorType.FORBIDDEN);
        }
        if (ex instanceof AuthenticationException) {
            return build(ex, env, ErrorType.UNAUTHORIZED);
        }
        if (ex instanceof IllegalArgumentException) {
            return build(ex, env, ErrorType.BAD_REQUEST);
        }
        return null;  // delega al handler por defecto
    }

    private GraphQLError build(Throwable ex, DataFetchingEnvironment env, ErrorType type) {
        return GraphqlErrorBuilder.newError(env)
                .errorType(type)
                .message(ex.getMessage())
                .build();
    }
}
