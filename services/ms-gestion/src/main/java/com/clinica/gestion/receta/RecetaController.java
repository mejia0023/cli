package com.clinica.gestion.receta;

import com.clinica.gestion.common.context.UsuarioContext;
import com.clinica.gestion.paciente.Paciente;
import com.clinica.gestion.paciente.PacienteRepository;
import com.clinica.gestion.usuario.RolEnum;
import com.clinica.gestion.usuario.Usuario;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;

import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class RecetaController {

    private final RecetaService recetaService;
    private final PacienteRepository pacienteRepository;

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
        Usuario u = UsuarioContext.current();
        if (u == null) throw new AccessDeniedException("Usuario no autenticado");
        return recetaService.listarPorMedico(u.getSupabaseUid());
    }

    @QueryMapping
    @PreAuthorize("hasRole('PACIENTE')")
    public List<Receta> misRecetasPaciente() {
        Usuario u = UsuarioContext.current();
        if (u == null) throw new AccessDeniedException("Usuario no autenticado");
        return pacienteRepository.findBySupabaseUid(u.getSupabaseUid())
                .map(Paciente::getId)
                .map(recetaService::listarPorPaciente)
                .orElse(Collections.emptyList());
    }

    @MutationMapping
    @PreAuthorize("hasRole('MEDICO')")
    public Receta emitirReceta(@Argument @Valid RecetaInput input) {
        Usuario u = UsuarioContext.current();
        if (u != null && u.getRol() != null && u.getRol().asEnum() == RolEnum.MEDICO) {
            // forzar medicoUid = supabase_uid del JWT, ignorar lo que envia el cliente
            RecetaInput safe = new RecetaInput(
                    input.pacienteId(), u.getNombre(), u.getSupabaseUid(),
                    input.diagnostico(), input.detalles());
            return recetaService.emitir(safe);
        }
        return recetaService.emitir(input);
    }

    @QueryMapping
    @PreAuthorize("hasAnyRole('ADMINISTRADOR','MEDICO','FARMACEUTICO')")
    public VerificacionReceta verificarReceta(@Argument UUID id) {
        return recetaService.verificarReceta(id);
    }
}
