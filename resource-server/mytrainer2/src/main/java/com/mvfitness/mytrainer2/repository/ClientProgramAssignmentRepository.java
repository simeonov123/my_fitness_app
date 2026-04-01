package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.domain.ClientProgramAssignment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClientProgramAssignmentRepository extends JpaRepository<ClientProgramAssignment, Long> {
    List<ClientProgramAssignment> findByClientOrderByAssignedAtDesc(Client client);
}
