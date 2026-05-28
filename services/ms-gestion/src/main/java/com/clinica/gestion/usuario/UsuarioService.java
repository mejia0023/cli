package com.clinica.gestion.usuario;

import com.clinica.gestion.common.exception.BusinessException;
import com.clinica.gestion.common.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;

    @Transactional(readOnly = true)
    public List<Usuario> listar() {
        return usuarioRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Usuario findById(UUID id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Usuario", id));
    }

    @Transactional(readOnly = true)
    public Usuario findBySupabaseUid(String uid) {
        return usuarioRepository.findBySupabaseUid(uid)
                .orElseThrow(() -> new NotFoundException("Usuario con supabase_uid=" + uid));
    }

    /**
     * Lazy provisioning: si el usuario no existe (primer login), lo crea con los datos del JWT.
     */
    @Transactional
    public Usuario findOrCreate(String supabaseUid, String email, String nombre, RolEnum rolEnum) {
        return usuarioRepository.findBySupabaseUid(supabaseUid)
                .orElseGet(() -> {
                    Rol rol = rolRepository.findById(rolEnum.getId())
                            .orElseThrow(() -> new BusinessException("Rol no encontrado: " + rolEnum));
                    Usuario nuevo = Usuario.builder()
                            .supabaseUid(supabaseUid)
                            .email(email)
                            .nombre(nombre != null ? nombre : email)
                            .rol(rol)
                            .activo(true)
                            .build();
                    return usuarioRepository.save(nuevo);
                });
    }

    @Transactional
    public Usuario cambiarRol(UUID id, RolEnum nuevoRol) {
        Usuario u = findById(id);
        Rol rol = rolRepository.findById(nuevoRol.getId())
                .orElseThrow(() -> new BusinessException("Rol no encontrado: " + nuevoRol));
        u.setRol(rol);
        return usuarioRepository.save(u);
    }

    @Transactional
    public Usuario desactivar(UUID id) {
        Usuario u = findById(id);
        u.setActivo(false);
        return usuarioRepository.save(u);
    }
}
