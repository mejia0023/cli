package com.clinica.gestion.usuario;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UsuarioRepository extends JpaRepository<Usuario, UUID> {
    Optional<Usuario> findBySupabaseUid(String supabaseUid);
    Optional<Usuario> findByEmail(String email);
}
