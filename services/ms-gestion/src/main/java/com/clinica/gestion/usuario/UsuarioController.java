package com.clinica.gestion.usuario;

import com.clinica.gestion.common.context.UsuarioContext;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;

import java.util.List;
import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    @QueryMapping
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    public List<Usuario> usuarios() {
        return usuarioService.listar();
    }

    @QueryMapping
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    public Usuario usuario(@Argument UUID id) {
        return usuarioService.findById(id);
    }

    @QueryMapping
    public Usuario me() {
        return UsuarioContext.current();
    }

    @MutationMapping
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    public Usuario cambiarRolUsuario(@Argument UUID id, @Argument RolEnum rol) {
        return usuarioService.cambiarRol(id, rol);
    }

    @MutationMapping
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    public Usuario desactivarUsuario(@Argument UUID id) {
        return usuarioService.desactivar(id);
    }

    @SchemaMapping(typeName = "Usuario", field = "rol")
    public RolEnum rolDeUsuario(Usuario usuario) {
        return usuario.getRol().asEnum();
    }
}
