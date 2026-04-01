package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.domain.ClientProgramAssignment;
import com.mvfitness.mytrainer2.domain.Program;
import com.mvfitness.mytrainer2.domain.ProgramTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClientProgramAssignmentRepository extends JpaRepository<ClientProgramAssignment, Long> {
    List<ClientProgramAssignment> findByClientOrderByAssignedAtDesc(Client client);

    List<ClientProgramAssignment> findByProgramIn(List<Program> programs);

    boolean existsByClientAndProgram_ProgramTemplate(Client client, ProgramTemplate programTemplate);

    void deleteByProgramIn(List<Program> programs);
}
