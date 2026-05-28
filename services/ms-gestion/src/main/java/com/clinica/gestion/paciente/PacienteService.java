package com.clinica.gestion.paciente;

import com.clinica.gestion.common.exception.BusinessException;
import com.clinica.gestion.common.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PacienteService {

    private final PacienteRepository pacienteRepository;

    @Transactional(readOnly = true)
    public List<Paciente> listar(String q) {
        return (q == null || q.isBlank()) ? pacienteRepository.findAll() : pacienteRepository.buscar(q);
    }

    @Transactional(readOnly = true)
    public Paciente findById(UUID id) {
        return pacienteRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Paciente", id));
    }

    @Transactional
    public Paciente crear(PacienteInput in) {
        if (pacienteRepository.findByCi(in.ci()).isPresent()) {
            throw new BusinessException("Ya existe un paciente con CI " + in.ci());
        }
        Paciente p = Paciente.builder()
                .ci(in.ci()).nombre(in.nombre()).apellido(in.apellido())
                .telefono(in.telefono()).email(in.email())
                .fechaNacimiento(in.fechaNacimiento())
                .supabaseUid(in.supabaseUid())
                .build();
        return pacienteRepository.save(p);
    }

    @Transactional
    public Paciente actualizar(UUID id, PacienteInput in) {
        Paciente p = findById(id);
        p.setNombre(in.nombre());
        p.setApellido(in.apellido());
        p.setTelefono(in.telefono());
        p.setEmail(in.email());
        p.setFechaNacimiento(in.fechaNacimiento());
        return pacienteRepository.save(p);
    }
}
