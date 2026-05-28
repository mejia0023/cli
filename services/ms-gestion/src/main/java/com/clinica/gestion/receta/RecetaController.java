package com.clinica.gestion.receta;

import com.clinica.gestion.paciente.Paciente;
import com.clinica.gestion.paciente.PacienteRepository;
import com.clinica.gestion.usuario.Usuario;
import com.clinica.gestion.usuario.UsuarioRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Controller;

import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class RecetaController {

    private final RecetaService recetaService;
    private final PacienteRepository pacienteRepository;
    private final UsuarioRepository usuarioRepository;

    @QueryMapping
    @PreAuthorize("hasAnyRole('ADMINISTRADOR','MEDICO','FARMACEUTICO')")
    public Receta receta(@Argument UUID id) {
        return recetaService.findById(id);
    }

    @QueryMapping
    @PreAuthorize("hasAnyRole('ADMINISTRADOR','MEDICO','FARMACEUTICO')")
    public List<Receta> recetasPorPaciente(@Argument UUID pacienteId) {
        return recetaService.listarPorPaciente(pacienteId);
    }

    @QueryMapping
    @PreAuthorize("hasRole('MEDICO')")
    public List<Receta> misRecetas() {
        String uid = currentSupabaseUid();
        return recetaService.listarPorMedico(uid);
    }

    @QueryMapping
    @PreAuthorize("hasRole('PACIENTE')")
    public List<Receta> misRecetasPaciente() {
        String uid = currentSupabaseUid();
        return pacienteRepository.findBySupabaseUid(uid)
                .map(Paciente::getId)
                .map(recetaService::listarPorPaciente)
                .orElse(Collections.emptyList());
    }

    @MutationMapping
    @PreAuthorize("hasRole('MEDICO')")
    public Receta emitirReceta(@Argument @Valid RecetaInput input) {
        String uid = currentSupabaseUid();
        Usuario u = usuarioRepository.findBySupabaseUid(uid).orElse(null);
        if (u != null) {
            // forzar medicoUid = supabase_uid del JWT, ignorar lo que envia el cliente
            RecetaInput safe = new RecetaInput(
                    input.pacienteId(), u.getNombre(), u.getSupabaseUid(),
                    input.diagnostico(), input.detalles());
            return recetaService.emitir(safe);
        }
        return recetaService.emitir(input);
    }

    @QueryMapping
    @PreAuthorize("hasAnyRole('ADMINISTRADOR','MEDICO','FARMACEUTICO','PACIENTE')")
    public VerificacionReceta verificarReceta(@Argument UUID id) {
        return recetaService.verificarReceta(id);
    }

    /**
     * Lee el subject del JWT actual directamente del SecurityContext.
     * Evita la dependencia del ThreadLocal UsuarioContext que no se propaga
     * entre el filter y los resolvers GraphQL.
     */
    private String currentSupabaseUid() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (!(auth instanceof JwtAuthenticationToken jwt)) {
            throw new AccessDeniedException("Usuario no autenticado");
        }
        return jwt.getToken().getSubject();
    }
}
