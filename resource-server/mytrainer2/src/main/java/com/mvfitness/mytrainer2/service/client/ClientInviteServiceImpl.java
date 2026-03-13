package com.mvfitness.mytrainer2.service.client;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.domain.ClientInvite;
import com.mvfitness.mytrainer2.domain.ClientInviteStatus;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.dto.ClientInviteDto;
import com.mvfitness.mytrainer2.dto.ClientInviteValidationDto;
import com.mvfitness.mytrainer2.repository.ClientInviteRepository;
import com.mvfitness.mytrainer2.repository.ClientRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class ClientInviteServiceImpl implements ClientInviteService {

    private final ClientInviteRepository invites;
    private final ClientRepository clients;
    private final UserRepository users;

    @Value("${app.client-invite-base-url:mytrainer://invite/client}")
    private String inviteBaseUrl;

    @Value("${app.client-web-invite-base-url:http://localhost/onboard/client}")
    private String webInviteBaseUrl;

    private User trainerOr404(String kcUserId) {
        User u = users.findByKeycloakUserId(kcUserId);
        if (u == null) {
            throw new IllegalArgumentException("Trainer not found for KC id: " + kcUserId);
        }
        return u;
    }

    private Client ownedClientOr404(String kcUserId, Long clientId) {
        User trainer = trainerOr404(kcUserId);
        Client client = clients.findById(clientId)
                .orElseThrow(() -> new IllegalArgumentException("Client not found or not yours"));
        if (client.getUser() == null || !trainer.getId().equals(client.getUser().getId())) {
            throw new IllegalArgumentException("Client not found or not yours");
        }
        return client;
    }

    private ClientInvite ownedInviteOr404(String kcUserId, Long clientId, Long inviteId) {
        Client client = ownedClientOr404(kcUserId, clientId);
        ClientInvite invite = invites.findById(inviteId)
                .orElseThrow(() -> new IllegalArgumentException("Invite not found"));
        if (!invite.getClient().getId().equals(client.getId())) {
            throw new IllegalArgumentException("Invite not found");
        }
        return invite;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClientInviteDto> list(String kcUserId, Long clientId) {
        Client client = ownedClientOr404(kcUserId, clientId);
        return invites.findByClientOrderByCreatedAtDesc(client).stream()
                .map(this::toDto)
                .toList();
    }

    @Override
    public ClientInviteDto create(String kcUserId, Long clientId) {
        Client client = ownedClientOr404(kcUserId, clientId);
        User trainer = trainerOr404(kcUserId);

        invites.findFirstByTrainerAndClientAndStatusOrderByCreatedAtDesc(
                        trainer,
                        client,
                        ClientInviteStatus.PENDING
                )
                .ifPresent(existing -> {
                    existing.setStatus(ClientInviteStatus.REVOKED);
                    invites.save(existing);
                });

        ClientInvite invite = invites.save(ClientInvite.builder()
                .trainer(trainer)
                .client(client)
                .inviteToken(newToken())
                .status(ClientInviteStatus.PENDING)
                .expiresAt(LocalDateTime.now().plusDays(7))
                .build());

        return toDto(invite);
    }

    @Override
    public ClientInviteDto regenerate(String kcUserId, Long clientId, Long inviteId) {
        ClientInvite existing = ownedInviteOr404(kcUserId, clientId, inviteId);
        existing.setStatus(ClientInviteStatus.REVOKED);
        invites.save(existing);
        return create(kcUserId, clientId);
    }

    @Override
    public ClientInviteDto revoke(String kcUserId, Long clientId, Long inviteId) {
        ClientInvite invite = ownedInviteOr404(kcUserId, clientId, inviteId);
        if (invite.getStatus() == ClientInviteStatus.PENDING) {
            invite.setStatus(ClientInviteStatus.REVOKED);
        }
        return toDto(invites.save(invite));
    }

    @Override
    @Transactional(readOnly = true)
    public ClientInviteValidationDto validate(String inviteToken) {
        ClientInvite invite = invites.findByInviteToken(inviteToken)
                .orElseThrow(() -> new IllegalArgumentException("Invite not found"));

        ClientInviteStatus status = invite.getStatus();
        if (status == ClientInviteStatus.PENDING && invite.getExpiresAt().isBefore(LocalDateTime.now())) {
            status = ClientInviteStatus.EXPIRED;
        }

        return new ClientInviteValidationDto(
                status == ClientInviteStatus.PENDING,
                status.name(),
                invite.getTrainer().getFullName(),
                invite.getClient().getId(),
                invite.getClient().getFullName(),
                invite.getClient().getEmail(),
                invite.getClient().getAccountUser() != null
        );
    }

    @Override
    public ClientInviteValidationDto accept(String inviteToken, JwtAuthenticationToken auth) {
        ClientInvite invite = invites.findByInviteToken(inviteToken)
                .orElseThrow(() -> new IllegalArgumentException("Invite not found"));

        if (invite.getStatus() != ClientInviteStatus.PENDING) {
            return validate(inviteToken);
        }

        if (invite.getExpiresAt().isBefore(LocalDateTime.now())) {
            invite.setStatus(ClientInviteStatus.EXPIRED);
            invites.save(invite);
            return validate(inviteToken);
        }

        Client client = invite.getClient();
        if (client.getAccountUser() != null) {
            return validate(inviteToken);
        }

        User user = upsertClientUser(auth);
        clients.findByAccountUser(user).ifPresent(existingClient -> {
            if (!existingClient.getId().equals(client.getId())) {
                throw new IllegalArgumentException("This account is already linked to another client profile");
            }
        });
        client.setAccountUser(user);
        clients.save(client);

        invite.setStatus(ClientInviteStatus.ACCEPTED);
        invite.setAcceptedAt(LocalDateTime.now());
        invite.setAcceptedByUserId(user.getKeycloakUserId());
        invites.save(invite);

        return validate(inviteToken);
    }

    private ClientInviteDto toDto(ClientInvite invite) {
        return new ClientInviteDto(
                invite.getId(),
                invite.getClient().getId(),
                invite.getClient().getFullName(),
                invite.getClient().getEmail(),
                invite.getStatus().name(),
                invite.getInviteToken(),
                inviteBaseUrl + "?token=" + invite.getInviteToken(),
                webInviteBaseUrl + "?token=" + invite.getInviteToken(),
                invite.getExpiresAt(),
                invite.getAcceptedAt(),
                invite.getCreatedAt()
        );
    }

    private String newToken() {
        return UUID.randomUUID().toString().replace("-", "")
                + UUID.randomUUID().toString().replace("-", "");
    }

    @SuppressWarnings("unchecked")
    private User upsertClientUser(JwtAuthenticationToken auth) {
        String keycloakUserId = auth.getToken().getSubject();
        String fullName = auth.getToken().getClaimAsString("name");
        String email = auth.getToken().getClaimAsString("email");

        User existing = users.findByKeycloakUserId(keycloakUserId);
        if (existing != null) {
            if ("TRAINER".equalsIgnoreCase(existing.getRole())) {
                throw new IllegalArgumentException(
                        "Trainer accounts cannot accept client invites. Sign in with a separate client account."
                );
            }
            existing.setFullName(fullName);
            existing.setEmail(email);
            existing.setRole("CLIENT");
            return users.save(existing);
        }

        User created = User.builder()
                .keycloakUserId(keycloakUserId)
                .fullName(fullName)
                .email(email)
                .role("CLIENT")
                .build();
        return users.save(created);
    }
}
