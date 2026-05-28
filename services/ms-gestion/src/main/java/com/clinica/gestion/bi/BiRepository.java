package com.clinica.gestion.bi;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface BiRepository {

    interface VentasDiarias extends JpaRepository<VentaDiariaPoint, LocalDate> {
        @Query("select v from VentaDiariaPoint v " +
                "where (:desde is null or v.dia >= :desde) and (:hasta is null or v.dia <= :hasta) " +
                "order by v.dia desc")
        List<VentaDiariaPoint> findRange(LocalDate desde, LocalDate hasta);
    }

    interface TopMedicamentos extends JpaRepository<TopMedicamentoItem, UUID> {
    }

    interface Inventario extends JpaRepository<InventarioCriticoItem, UUID> {
    }

    interface RecetasBlockchain extends JpaRepository<RecetaBlockchainPoint, LocalDate> {
        @Query("select r from RecetaBlockchainPoint r " +
                "where (:desde is null or r.mes >= :desde) and (:hasta is null or r.mes <= :hasta) " +
                "order by r.mes desc")
        List<RecetaBlockchainPoint> findRange(LocalDate desde, LocalDate hasta);
    }
}
