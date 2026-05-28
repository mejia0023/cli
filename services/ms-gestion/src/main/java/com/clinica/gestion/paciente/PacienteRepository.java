package com.clinica.gestion.paciente;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PacienteRepository extends JpaRepository<Paciente, UUID> {
    Optional<Paciente> findByCi(String ci);
    Optional<Paciente> findBySupabaseUid(String supabaseUid);

    @Query("select p from Paciente p where lower(p.nombre) like lower(concat('%', :q, '%')) " +
            "or lower(p.apellido) like lower(concat('%', :q, '%')) " +
            "or p.ci like concat('%', :q, '%')")
    List<Paciente> buscar(String q);
}
