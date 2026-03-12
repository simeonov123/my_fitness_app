package com.mvfitness.mytrainer2.service.session;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.domain.TrainingSession;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.repository.TrainingSessionRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TrainingSessionAccessService {

    private final UserRepository users;
    private final TrainingSessionRepository sessions;

    public boolean canAccess(String keycloakUserId, Long sessionId) {
        User user = users.findByKeycloakUserId(keycloakUserId);
        if (user == null) {
            return false;
        }

        TrainingSession session = sessions.findWithClientsById(sessionId).orElse(null);
        if (session == null) {
            return false;
        }

        if (session.getTrainer() != null
                && keycloakUserId.equals(session.getTrainer().getKeycloakUserId())) {
            return true;
        }

        for (Client client : session.getClients()) {
            if (client.getAccountUser() != null
                    && client.getAccountUser().getId().equals(user.getId())) {
                return true;
            }
        }

        return false;
    }
}
