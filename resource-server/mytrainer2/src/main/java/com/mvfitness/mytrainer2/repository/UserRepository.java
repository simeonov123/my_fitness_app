package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    User findByKeycloakUserId(String keycloakUserId);


}
