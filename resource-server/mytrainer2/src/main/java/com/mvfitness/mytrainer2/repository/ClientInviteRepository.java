package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.domain.ClientInvite;
import com.mvfitness.mytrainer2.domain.ClientInviteStatus;
import com.mvfitness.mytrainer2.domain.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClientInviteRepository extends JpaRepository<ClientInvite, Long> {

    List<ClientInvite> findByTrainerOrderByCreatedAtDesc(User trainer);

    List<ClientInvite> findByClientOrderByCreatedAtDesc(Client client);

    Optional<ClientInvite> findByInviteToken(String inviteToken);

    Optional<ClientInvite> findFirstByTrainerAndClientAndStatusOrderByCreatedAtDesc(
            User trainer,
            Client client,
            ClientInviteStatus status
    );
}
