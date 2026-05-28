package com.clinica.gestion.medicamento;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface MedicamentoRepository extends JpaRepository<Medicamento, UUID> {

    @Query("select m from Medicamento m where (:activo is null or m.activo = :activo) " +
            "and (:q is null or lower(m.nombre) like lower(concat('%', :q, '%')))")
    List<Medicamento> buscar(String q, Boolean activo);
}
