package com.clinica.gestion.paciente;

import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record PacienteInput(
        @NotBlank String ci,
        @NotBlank String nombre,
        @NotBlank String apellido,
        String telefono,
        String email,
        LocalDate fechaNacimiento,
        String supabaseUid
) {}
