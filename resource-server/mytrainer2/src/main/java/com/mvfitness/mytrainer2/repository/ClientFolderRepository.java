package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.ClientFolder;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClientFolderRepository extends JpaRepository<ClientFolder, Long> {
    List<ClientFolder> findByUserOrderBySequenceOrderAscIdAsc(User user);
}
