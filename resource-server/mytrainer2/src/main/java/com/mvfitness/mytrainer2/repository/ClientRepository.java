// src/main/java/com/mvfitness/mytrainer2/repository/ClientRepository.java
package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ClientRepository extends JpaRepository<Client, Long> {

    Page<Client> findByUserAndFullNameContainingIgnoreCase(
            User trainer,
            String search,
            Pageable pageable
    );
}
