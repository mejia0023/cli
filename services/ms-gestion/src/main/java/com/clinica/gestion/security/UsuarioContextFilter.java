package com.clinica.gestion.security;

import com.clinica.gestion.common.context.UsuarioContext;
import com.clinica.gestion.usuario.RolEnum;
import com.clinica.gestion.usuario.Usuario;
import com.clinica.gestion.usuario.UsuarioService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;

@Slf4j
@RequiredArgsConstructor
public class UsuarioContextFilter extends OncePerRequestFilter {

    private final UsuarioService usuarioService;

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwt) {
            try {
                String uid = jwt.getToken().getSubject();
                String email = jwt.getToken().getClaim("email");
                String nombre = extractNombre(jwt);
                RolEnum rol = extractRol(jwt);
                Usuario u = usuarioService.findOrCreate(uid, email, nombre, rol);
                UsuarioContext.set(u);
            } catch (Exception e) {
                log.warn("Error provisioning usuario desde JWT: {}", e.getMessage());
            }
        }
        try { chain.doFilter(req, res); }
        finally { UsuarioContext.clear(); }
    }

    private String extractNombre(JwtAuthenticationToken jwt) {
        Object userMeta = jwt.getToken().getClaim("user_metadata");
        if (userMeta instanceof Map<?,?> meta) {
            Object n = meta.get("name");
            if (n != null) return n.toString();
        }
        return jwt.getToken().getClaim("email");
    }

    private RolEnum extractRol(JwtAuthenticationToken jwt) {
        Object appMeta = jwt.getToken().getClaim("app_metadata");
        if (appMeta instanceof Map<?,?> meta) {
            Object role = meta.get("role");
            if (role != null) return RolEnum.fromString(role.toString());
        }
        return RolEnum.PACIENTE;
    }
}
