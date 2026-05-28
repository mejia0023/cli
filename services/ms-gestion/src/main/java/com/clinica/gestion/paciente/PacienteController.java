package com.clinica.gestion.paciente;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;

import java.util.List;
import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class PacienteController {

    private final PacienteService pacienteService;

    @QueryMapping
    @PreAuthorize("hasAnyRole('ADMINISTRADOR','FARMACEUTICO','MEDICO')")
    public List<Paciente> pacientes(@Argument String q) {
        return pacienteService.listar(q);
    }

    @QueryMapping
    @PreAuthorize("hasAnyRole('ADMINISTRADOR','FARMACEUTICO','MEDICO')")
    public Paciente paciente(@Argument UUID id) {
        return pacienteService.findById(id);
    }

    @MutationMapping
    @PreAuthorize("hasAnyRole('ADMINISTRADOR','FARMACEUTICO')")
    public Paciente crearPaciente(@Argument @Valid PacienteInput input) {
        return pacienteService.crear(input);
    }

    @MutationMapping
    @PreAuthorize("hasAnyRole('ADMINISTRADOR','FARMACEUTICO')")
    public Paciente actualizarPaciente(@Argument UUID id, @Argument @Valid PacienteInput input) {
        return pacienteService.actualizar(id, input);
    }
}
