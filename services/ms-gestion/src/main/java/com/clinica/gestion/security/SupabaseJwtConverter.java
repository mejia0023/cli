package com.clinica.gestion.security;

import com.clinica.gestion.usuario.RolEnum;
import com.clinica.gestion.usuario.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class SupabaseJwtConverter implements Converter<Jwt, AbstractAuthenticationToken> {

    private final UsuarioRepository usuarioRepository;

    @Override
    public AbstractAuthenticationToken convert(Jwt jwt) {
        RolEnum rol = extractRol(jwt);
        var authorities = List.of(new SimpleGrantedAuthority(rol.authority()));
        return new JwtAuthenticationToken(jwt, authorities, jwt.getSubject());
    }

    private RolEnum extractRol(Jwt jwt) {
        // 1) claim app_metadata.role (preferido — setealo en Supabase Dashboard)
        Object appMeta = jwt.getClaim("app_metadata");
        if (appMeta instanceof Map<?,?> meta) {
            Object role = meta.get("role");
            if (role != null) return RolEnum.fromString(role.toString());
        }
        // 2) claim user_metadata.role (fallback)
        Object userMeta = jwt.getClaim("user_metadata");
        if (userMeta instanceof Map<?,?> meta) {
            Object role = meta.get("role");
            if (role != null) return RolEnum.fromString(role.toString());
        }
        // 3) Fallback a BD por supabase_uid (cubre usuarios seedeados sin claims en Supabase)
        String uid = jwt.getSubject();
        if (uid != null) {
            var u = usuarioRepository.findBySupabaseUid(uid);
            if (u.isPresent() && u.get().getRol() != null) {
                return u.get().getRol().asEnum();
            }
        }
        log.warn("JWT sub={} sin rol en claims ni en BD — asignando PACIENTE", uid);
        return RolEnum.PACIENTE;
    }
}
